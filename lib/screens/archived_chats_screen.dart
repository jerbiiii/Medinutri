import 'package:flutter/material.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Journal des Consultations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () => _showDeleteDialog(context, healthProvider),
            tooltip: "Tout effacer",
          ),
        ],
      ),
      body: FutureBuilder<List<Conversation>>(
        future: healthProvider.getArchivedConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey[200]),
                  const SizedBox(height: 24),
                  Text(
                    "Aucun historique pour le moment",
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.chat_bubble_outline, color: theme.primaryColor, size: 20),
                ),
                title: Text(
                  conv.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(conv.timestamp),
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[600], fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => ConversationDetailScreen(conversation: conv))
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, HealthProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Effacer l'historique ?"),
        content: const Text("Toutes vos conversations sauvegardées seront définitivement supprimées."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              await provider.deleteArchivedMessages();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Historique effacé")),
                );
              }
            },
            child: const Text("Tout supprimer", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class ConversationDetailScreen extends StatelessWidget {
  final Conversation conversation;
  const ConversationDetailScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(conversation.title, style: const TextStyle(fontSize: 18)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: conversation.messages.length,
        itemBuilder: (context, index) {
          final message = conversation.messages[index];
          final isUser = message['role'] == 'user';
          return _buildMessageBubble(context, message['content']!, isUser, isDark, theme);
        },
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, String text, bool isUser, bool isDark, ThemeData theme) {
    final primaryColor = theme.primaryColor;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isUser 
            ? LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) 
            : null,
          color: isUser ? null : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
          border: !isUser && isDark ? Border.all(color: Colors.white10) : null,
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: isUser 
          ? Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            )
          : MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, height: 1.5),
                strong: TextStyle(color: isDark ? Colors.blue[300] : theme.primaryColor, fontWeight: FontWeight.bold),
                h1: TextStyle(color: theme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                h2: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
      ),
    );
  }
}

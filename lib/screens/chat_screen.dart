import 'package:flutter/material.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _jumpToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _updateAppTheme(String response, ThemeNotifier themeNotifier) {
    final lowerCaseRes = response.toLowerCase();
    if (lowerCaseRes.contains("urgence") || lowerCaseRes.contains("immédiatement")) {
      themeNotifier.updateTheme(newColor: Colors.redAccent);
    } else if (lowerCaseRes.contains("obésité") || lowerCaseRes.contains("maigre")) {
      themeNotifier.updateTheme(newColor: Colors.orangeAccent);
    } else if (lowerCaseRes.contains("plan nutritionnel")) {
      themeNotifier.updateTheme(newColor: Colors.greenAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Docteur IA"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: () => _showClearDialog(healthProvider),
            tooltip: "Vider la conversation",
          ),
          IconButton(
            onPressed: () => themeNotifier.resetTheme(), 
            icon: const Icon(Icons.refresh_outlined),
            tooltip: "Réinitialiser le thème",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: healthProvider.messages.length,
              itemBuilder: (context, index) {
                final message = healthProvider.messages[index];
                final isUser = message['role'] == 'user';
                return _buildMessageBubble(message['content']!, isUser, isDark, theme)
                    .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
              },
            ),
          ),
          if (healthProvider.isTyping)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SpinKitThreeBounce(color: theme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "Le docteur analyse...",
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: _buildInputArea(healthProvider, themeNotifier, isDark, theme),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(HealthProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vider la conversation ?"),
        content: const Text("L'historique actuel sera archivé et masqué."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () {
              provider.clearChat();
              Navigator.pop(context);
            },
            child: const Text("Vider", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, bool isDark, ThemeData theme) {
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
          color: isUser ? null : (isDark ? const Color(0xFF121212) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
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
                p: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, height: 1.5),
                strong: TextStyle(color: isDark ? Colors.blue[300] : theme.primaryColor, fontWeight: FontWeight.bold),
                h1: TextStyle(color: theme.primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
                h2: TextStyle(color: theme.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                listBullet: TextStyle(color: theme.primaryColor, fontSize: 16),
                code: TextStyle(backgroundColor: isDark ? Colors.white10 : Colors.grey[200]),
              ),
            ),
      ),
    );
  }

  Widget _buildInputArea(HealthProvider provider, ThemeNotifier themeNotifier, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), // Rehaussé de 8 à 28
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Décrivez vos symptômes...",
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                filled: true,
                fillColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24), 
                  borderSide: isDark ? const BorderSide(color: Colors.white10) : BorderSide.none
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: IconButton.filled(
              onPressed: provider.isTyping ? null : () async {
                if (_controller.text.trim().isEmpty) return;
                final text = _controller.text;
                _controller.clear();
                _scrollToBottom();
                await provider.analyzeSymptoms(text);
                if (mounted && provider.messages.isNotEmpty) {
                  _updateAppTheme(provider.messages.last['content']!, themeNotifier);
                }
                _scrollToBottom();
              },
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

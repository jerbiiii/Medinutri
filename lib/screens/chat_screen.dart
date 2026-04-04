import 'package:flutter/material.dart';
import 'package:medinutri/services/health_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final hp = Provider.of<HealthProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Docteur IA', style: TextStyle(fontSize: 18)),
            if (hp.currentProfile != null)
              Text(
                hp.currentProfile!.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[500],
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.redAccent,
            ),
            onPressed: () => _showClearDialog(hp),
            tooltip: 'Archiver la conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Bandeau info profil ──────────────────────
          if (hp.messages.isEmpty && hp.currentProfile != null)
            _buildWelcomeBanner(hp, isDark, theme),

          // ── Liste de messages ────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: hp.messages.length,
              itemBuilder: (ctx, i) {
                final msg = hp.messages[i];
                final isUser = msg['role'] == 'user';
                return _buildBubble(
                  msg['content']!,
                  isUser,
                  isDark,
                  theme,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
              },
            ),
          ),

          // ── Indicateur de frappe ─────────────────────
          if (hp.isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  SpinKitThreeBounce(color: theme.primaryColor, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    'Le docteur analyse...',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // ── Zone de saisie ───────────────────────────
          SafeArea(child: _buildInputArea(hp, isDark, theme)),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(HealthProvider hp, bool isDark, ThemeData theme) {
    final p = hp.currentProfile!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.waving_hand, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Bonjour ${p.name} !',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Je connais votre profil : ${p.age} ans, ${p.weight} kg, IMC ${p.bmi.toStringAsFixed(1)} (${p.bmiStatus}).\n'
            'Décrivez vos symptômes ou posez-moi une question de santé.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  void _showClearDialog(HealthProvider hp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archiver la conversation ?'),
        content: const Text(
          'La conversation sera archivée et un nouveau chat sera ouvert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await hp.clearChat();
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Archiver',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser, bool isDark, ThemeData theme) {
    final primary = theme.primaryColor;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser
              ? null
              : (isDark ? const Color(0xFF161616) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: !isUser && isDark ? Border.all(color: Colors.white10) : null,
        ),
        child: isUser
            ? Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              )
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.55,
                  ),
                  strong: TextStyle(
                    color: isDark ? Colors.blue[300] : theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  h1: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 15,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInputArea(HealthProvider hp, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
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
                hintText: 'Décrivez vos symptômes...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF161616) : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: isDark
                      ? const BorderSide(color: Colors.white12)
                      : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: IconButton.filled(
              onPressed: hp.isTyping
                  ? null
                  : () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      _controller.clear();
                      _scrollToBottom();
                      await hp.analyzeSymptoms(text);
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

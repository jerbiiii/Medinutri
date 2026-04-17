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
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Docteur IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                  SpinKitThreeBounce(color: const Color(0xFF0D9488), size: 18),
                  const SizedBox(width: 12),
                  Text(
                    'Le docteur analyse...',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[500],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Glassmorphism-lite
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFF0D9488).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D9488).withValues(alpha: 0.15),
                      const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.waving_hand, color: Color(0xFF0D9488), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Bonjour ${p.name} !',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D9488),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Je connais votre profil : ${p.age} ans, ${p.weight} kg, IMC ${p.bmi.toStringAsFixed(1)} (${p.bmiStatus}).\n'
            'Décrivez vos symptômes ou posez-moi une question de santé.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
  }

  void _showClearDialog(HealthProvider hp) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archiver la conversation ?'),
        content: const Text(
          'La conversation sera archivée et un nouveau chat sera ouvert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await hp.clearChat();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
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
              ? const LinearGradient(
                  colors: ThemeNotifier.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser
              ? null
              : (isDark ? const Color(0xFF161616) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? const Color(0xFF0D9488).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: !isUser
              ? Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.08),
                )
              : null,
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
                  strong: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.bold,
                  ),
                  h1: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 15,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInputArea(HealthProvider hp, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF161616) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Gradient send button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: ThemeNotifier.primaryGradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
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
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}

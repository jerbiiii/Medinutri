import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/screens/register_screen.dart';
import 'package:medinutri/screens/home_screen.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      } else if (mounted) {
        // Success: Navigate to HomeScreen and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // ── Decorative circles ──────────────────
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF0D9488).withValues(alpha: 0.15),
                              const Color(0xFF0D9488).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      // Logo circle
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(duration: 600.ms).scale(duration: 600.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 24),

                // ── Title ───────────────────────────────
                Text(
                  "Bienvenue sur MediNutri",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ).animate(delay: 200.ms).fade(duration: 600.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 6),
                Text(
                  "Votre santé au quotidien",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white60 : Colors.grey[500],
                  ),
                ).animate(delay: 300.ms).fade(duration: 600.ms),

                const SizedBox(height: 48),

                // ── Username field ──────────────────────
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Nom d'utilisateur",
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: isDark ? Colors.white60 : Colors.grey[500],
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? "Champ requis" : null,
                ).animate(delay: 400.ms).fade(duration: 500.ms).slideY(begin: 0.15, end: 0),

                const SizedBox(height: 16),

                // ── Password field ──────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark ? Colors.white60 : Colors.grey[500],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.white60 : Colors.grey[500],
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? "Champ requis" : null,
                ).animate(delay: 500.ms).fade(duration: 500.ms).slideY(begin: 0.15, end: 0),

                const SizedBox(height: 36),

                // ── Login button (gradient) ─────────────
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: ThemeNotifier.primaryGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text("Se connecter", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ).animate(delay: 600.ms).fade(duration: 500.ms).slideY(begin: 0.15, end: 0),

                const SizedBox(height: 28),

                // ── Register link ───────────────────────
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Pas encore de compte ? ",
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(
                          text: "S'inscrire",
                          style: TextStyle(
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: 700.ms).fade(duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

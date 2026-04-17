import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/screens/home_screen.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _gender = "Homme";
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final profile = PatientProfile(
        userId: '', // Id temporaire remplacé par le AuthProvider
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        weight: double.parse(_weightController.text.trim()),
        height: double.parse(_heightController.text.trim()),
      );

      final error = await authProvider.signUp(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        profile,
      );

      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      } else if (mounted) {
        // Signup auto-logs the user in — go directly to HomeScreen
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Title section ───────────────────────
                Text(
                  "Créer un compte",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ).animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),
                Text(
                  "Remplissez vos informations de base pour commencer.",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[500],
                    fontSize: 14,
                  ),
                ).animate(delay: 100.ms).fade(duration: 500.ms),

                const SizedBox(height: 32),

                // ── Section: Compte ─────────────────────
                _buildSectionTitle("Informations de compte", Icons.account_circle_outlined, isDark)
                    .animate(delay: 150.ms).fade(duration: 500.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 16),

                _buildField("Nom d'utilisateur", _usernameController, Icons.person_outline, isDark)
                    .animate(delay: 200.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                _buildField(
                  "Mot de passe",
                  _passwordController,
                  Icons.lock_outline,
                  isDark,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white60 : Colors.grey[500],
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ).animate(delay: 250.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                _buildField(
                  "Confirmer le mot de passe",
                  _confirmPasswordController,
                  Icons.lock_reset_outlined,
                  isDark,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white60 : Colors.grey[500],
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) => val != _passwordController.text ? "Les mots de passe ne correspondent pas" : null,
                ).animate(delay: 300.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 32),

                // ── Section: Santé ──────────────────────
                _buildSectionTitle("Informations de santé", Icons.favorite_outline, isDark)
                    .animate(delay: 350.ms).fade(duration: 500.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 16),

                _buildField("Nom complet", _nameController, Icons.badge_outlined, isDark)
                    .animate(delay: 400.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField("Âge", _ageController, Icons.cake_outlined, isDark, keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161616) : Colors.grey[50],
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _gender,
                            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                            items: ["Homme", "Femme", "Autre"].map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (newValue) => setState(() => _gender = newValue!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 450.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField("Poids (kg)", _weightController, Icons.monitor_weight_outlined, isDark, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField("Taille (cm)", _heightController, Icons.straighten_outlined, isDark, keyboardType: TextInputType.number)),
                  ],
                ).animate(delay: 500.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 48),

                // ── Sign-up button (gradient) ───────────
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
                    onPressed: isLoading ? null : _handleSignUp,
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
                        : const Text("S'inscrire", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ).animate(delay: 550.ms).fade(duration: 500.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ThemeNotifier.primaryGradient,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: const Color(0xFF0D9488)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, bool isDark,
      {bool obscureText = false, Widget? suffixIcon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isDark ? Colors.white60 : Colors.grey[500]),
        suffixIcon: suffixIcon,
      ),
      validator: validator ?? ((value) => (value == null || value.isEmpty) ? "Champ requis" : null),
    );
  }
}

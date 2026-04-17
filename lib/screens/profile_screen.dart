import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/screens/archived_chats_screen.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late String _gender;
  late String _activityLevel;
  late String _goal;
  String? _photoPath;
  File? _localImageFile;
  bool _isPickingPhoto = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(context, listen: false).currentProfile;
    
    _nameController = TextEditingController(text: profile?.name ?? "");
    _ageController = TextEditingController(text: profile?.age.toString() ?? "");
    _weightController = TextEditingController(text: profile?.weight.toString() ?? "");
    _heightController = TextEditingController(text: profile?.height.toString() ?? "");
    _allergiesController = TextEditingController(text: profile?.allergies ?? "Aucune");
    _conditionsController = TextEditingController(text: profile?.medicalConditions ?? "Aucune");
    
    _gender = profile?.gender ?? "Homme";
    _activityLevel = profile?.activityLevel ?? "Modérée";
    _goal = profile?.goal ?? "Équilibre alimentaire";
    _photoPath = profile?.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  // ─── Sélectionner une photo ──────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // fermer le bottom sheet
    setState(() => _isPickingPhoto = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked == null) return;

      // Copier dans le dossier documents de l'app pour persistance
      final appDir = await getApplicationDocumentsDirectory();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? 'guest';
      final destPath = p.join(appDir.path, 'profile_photo_$userId.jpg');
      await File(picked.path).copy(destPath);

      setState(() {
        _photoPath = destPath;
        _localImageFile = File(destPath);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Changer la photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                title: const Text('Galerie photo'),
                subtitle: const Text('Choisir depuis vos photos'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF10B981),
                  ),
                ),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Ouvrir la caméra'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              if (_photoPath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                  title: const Text('Supprimer la photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _photoPath = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Enregistrer le profil ───────────────────────────
  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentProfile = authProvider.currentProfile;

      if (currentProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : profil non chargé. Veuillez vous reconnecter.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final updatedProfile = PatientProfile(
        id: currentProfile.id,
        userId: currentProfile.userId,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        weight: double.parse(_weightController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        activityLevel: _activityLevel,
        allergies: _allergiesController.text.trim(),
        medicalConditions: _conditionsController.text.trim(),
        goal: _goal,
        photoPath: _photoPath,
      );

      final error = await authProvider.updateProfile(
        updatedProfile,
        imageFile: _localImageFile,
      );
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur sauvegarde : $error'),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour !'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Mon Profil Santé')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo de profil with gradient border ──
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: ThemeNotifier.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF121212) : Colors.white,
                            border: Border.all(
                              color: isDark ? const Color(0xFF121212) : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _isPickingPhoto
                                ? Container(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                  )
                                : _localImageFile != null
                                    ? Image.file(
                                        _localImageFile!,
                                        fit: BoxFit.cover,
                                        width: 110,
                                        height: 110,
                                      )
                                    : (_photoPath != null &&
                                            _photoPath!.startsWith('http'))
                                        ? Image.network(
                                            _photoPath!,
                                            fit: BoxFit.cover,
                                            width: 110,
                                            height: 110,
                                            errorBuilder: (_, __, ___) => _personIcon(),
                                          )
                                        : (_photoPath != null &&
                                                File(_photoPath!).existsSync())
                                            ? Image.file(
                                                File(_photoPath!),
                                                fit: BoxFit.cover,
                                                width: 110,
                                                height: 110,
                                                errorBuilder: (_, __, ___) => _personIcon(),
                                              )
                                            : _personIcon(),
                          ),
                        ),
                      ),
                    ),
                    // Bouton caméra
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: ThemeNotifier.primaryGradient,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Appuyer pour modifier la photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Section: Infos personnelles ───────────
              _buildSectionTitle('Informations Personnelles', isDark)
                  .animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),
              const SizedBox(height: 16),

              _buildField(
                'Nom complet',
                _nameController,
                Icons.badge_outlined,
                isDark,
              ).animate().fadeIn(delay: 100.ms).slideX(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      'Âge',
                      _ageController,
                      Icons.cake_outlined,
                      isDark,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown(
                      value: _gender,
                      items: ['Homme', 'Femme', 'Autre'],
                      isDark: isDark,
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideX(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      'Poids (kg)',
                      _weightController,
                      Icons.monitor_weight_outlined,
                      isDark,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      'Taille (cm)',
                      _heightController,
                      Icons.straighten_outlined,
                      isDark,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideX(),
              const SizedBox(height: 28),

              // ── Section: Infos complémentaires ────────
              _buildSectionTitle('Informations Complémentaires', isDark)
                  .animate().fadeIn(delay: 350.ms).slideX(begin: -0.05, end: 0),
              const SizedBox(height: 16),
              _buildDropdown(
                label: "Niveau d'activité",
                value:
                    [
                      'Sédentaire',
                      'Modérée',
                      'Active',
                      'Très Active',
                    ].contains(_activityLevel)
                    ? _activityLevel
                    : 'Modérée',
                items: ['Sédentaire', 'Modérée', 'Active', 'Très Active'],
                isDark: isDark,
                onChanged: (val) => setState(() => _activityLevel = val!),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Objectif Santé',
                value:
                    [
                      'Perte de poids',
                      'Prise de masse',
                      'Rééquilibrage alimentaire',
                      "Plus d'énergie",
                    ].contains(_goal)
                    ? _goal
                    : 'Rééquilibrage alimentaire',
                items: [
                  'Perte de poids',
                  'Prise de masse',
                  'Rééquilibrage alimentaire',
                  "Plus d'énergie",
                ],
                isDark: isDark,
                onChanged: (val) => setState(() => _goal = val!),
              ),
              const SizedBox(height: 16),
              _buildField(
                'Allergies',
                _allergiesController,
                Icons.warning_amber_rounded,
                isDark,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Conditions Médicales',
                _conditionsController,
                Icons.medical_services_outlined,
                isDark,
              ),
              const SizedBox(height: 28),

              // ── Section: Sécurité ─────────────────────
              _buildSectionTitle('Sécurité & Historique', isDark)
                  .animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, end: 0),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121212) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? Border.all(color: Colors.white10) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Colors.orangeAccent,
                          size: 20,
                        ),
                      ),
                      title: const Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]),
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.archive_outlined,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      title: const Text('Conversations Archivées', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ArchivedChatsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(),
              const SizedBox(height: 40),

              // ── Save button (gradient) ────────────────
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
                  onPressed: _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Enregistrer les modifications',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
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
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    String? label,
    required String value,
    required List<String> items,
    required bool isDark,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161616) : Colors.grey[50],
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey[200]!,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              items: items
                  .map(
                    (v) => DropdownMenuItem<String>(value: v, child: Text(v)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Ancien mot de passe',
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                ),
                validator: (val) => (val == null || val.length < 6)
                    ? 'Minimum 6 caractères'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau',
                ),
                validator: (val) => val != newPasswordController.text
                    ? 'Ne correspond pas'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(colors: ThemeNotifier.primaryGradient),
            ),
            child: ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final error = await authProvider.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Mot de passe mis à jour !'),
                        backgroundColor: error != null
                            ? Colors.redAccent
                            : const Color(0xFF10B981),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Mettre à jour'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey[500]),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey[500]),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Champ requis' : null,
    );
  }

  Widget _personIcon() {
    return Container(
      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
      child: const Icon(
        Icons.person_rounded,
        size: 60,
        color: Color(0xFF0D9488),
      ),
    );
  }
}

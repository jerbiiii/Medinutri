import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/screens/archived_chats_screen.dart';
import 'package:medinutri/services/auth_provider.dart';
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
  bool _isPickingPhoto = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentProfile!;
    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _weightController = TextEditingController(text: profile.weight.toString());
    _heightController = TextEditingController(text: profile.height.toString());
    _allergiesController = TextEditingController(text: profile.allergies);
    _conditionsController = TextEditingController(
      text: profile.medicalConditions,
    );
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _goal = profile.goal;
    _photoPath = profile.photoPath;
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
      final userId = authProvider.currentUser?.id ?? 0;
      final destPath = p.join(appDir.path, 'profile_photo_$userId.jpg');
      await File(picked.path).copy(destPath);

      setState(() => _photoPath = destPath);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.blue,
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
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.green,
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
      final updatedProfile = PatientProfile(
        id: authProvider.currentProfile!.id,
        userId: authProvider.currentProfile!.userId,
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
      await authProvider.updateProfile(updatedProfile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Mon Profil Santé')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo de profil ──────────────────────
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primaryColor,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _isPickingPhoto
                              ? Container(
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _photoPath != null &&
                                    File(_photoPath!).existsSync()
                              ? Image.file(
                                  File(_photoPath!),
                                  fit: BoxFit.cover,
                                  width: 110,
                                  height: 110,
                                )
                              : Container(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 60,
                                    color: theme.primaryColor,
                                  ),
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
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
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
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Champs formulaire ────────────────────
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
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
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
              const SizedBox(height: 16),
              const Text(
                'Informations Complémentaires',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
              const SizedBox(height: 32),
              const Text(
                'Sécurité & Historique',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.lock_reset,
                        color: Colors.orangeAccent,
                      ),
                      title: const Text('Changer le mot de passe'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.archive_outlined,
                        color: Colors.blueAccent,
                      ),
                      title: const Text('Conversations Archivées'),
                      trailing: const Icon(Icons.chevron_right),
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
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _handleUpdate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enregistrer les modifications',
                  style: TextStyle(fontSize: 18),
                ),
              ).animate().fadeIn(delay: 500.ms).scale(),
            ],
          ),
        ),
      ),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
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
          ElevatedButton(
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
                          : Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Mettre à jour'),
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
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey[300]!,
          ),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Champ requis' : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/widgets/loading_overlay.dart';

class NutritionFormScreen extends StatefulWidget {
  const NutritionFormScreen({super.key});

  @override
  State<NutritionFormScreen> createState() => _NutritionFormScreenState();
}

class _NutritionFormScreenState extends State<NutritionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Preferences
  final Map<String, bool> _goals = {
    "Perte de poids": false,
    "Prise de masse": false,
    "Rééquilibrage alimentaire": true,
    "Plus d'énergie": false,
  };

  final Map<String, bool> _restrictions = {
    "Végétarien": false,
    "Sans Gluten": false,
    "Sans Lactose": false,
    "Autre": false,
  };

  final TextEditingController _otherController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(context, listen: false).currentProfile;
    if (profile != null) {
      _allergiesController.text = profile.allergies;
    }
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    
    try {
      final profile = authProvider.currentProfile;
      if (profile == null) return;

      List<String> selectedGoals = _goals.entries.where((e) => e.value).map((e) => e.key).toList();
      List<String> selectedRestrictions = _restrictions.entries.where((e) => e.value).map((e) => e.key).toList();
      if (_restrictions["Autre"]! && _otherController.text.isNotEmpty) {
        selectedRestrictions.add(_otherController.text.trim());
      }

      // 1. Update Profile first
      final updatedProfile = PatientProfile(
        id: profile.id,
        userId: profile.userId,
        name: profile.name,
        age: profile.age,
        gender: profile.gender,
        weight: profile.weight,
        height: profile.height,
        activityLevel: profile.activityLevel,
        allergies: _allergiesController.text.trim().isEmpty ? "Aucune" : _allergiesController.text.trim(),
        medicalConditions: selectedRestrictions.isEmpty ? "Aucune" : selectedRestrictions.join(", "),
        goal: selectedGoals.isEmpty ? "Équilibre alimentaire" : selectedGoals.join(", "),
      );

      await authProvider.updateProfile(updatedProfile);

      // 2. Generate Plan — pass the freshly updated profile to avoid stale cache
      await healthProvider.generateAndSavePlan(updatedProfile: updatedProfile);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Votre plan tunisien est prêt !"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la génération: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Préférences Nutrition")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Vos Objectifs"),
                  ..._goals.keys.map((goal) => _buildCheckbox(goal, _goals)),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle("Vos Allergies"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: InputDecoration(
                      hintText: "Ex: Arachides, fruits de mer...",
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),
                  _buildSectionTitle("Restrictions Alimentaires"),
                  ..._restrictions.keys.map((res) => Column(
                    children: [
                      _buildCheckbox(res, _restrictions),
                      if (res == "Autre" && _restrictions["Autre"]!)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextFormField(
                            controller: _otherController,
                            decoration: InputDecoration(
                              hintText: "Saisissez votre restriction",
                              filled: true,
                              fillColor: isDark ? Colors.white10 : Colors.grey[100],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ).animate().fadeIn().scale(alignment: Alignment.centerLeft),
                        ),
                    ],
                  )),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Générer mon programme", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ).animate().fadeIn(delay: 400.ms).scale(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const ModernLoadingOverlay(message: "Génération de votre plan tunisien..."),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ).animate().fadeIn().slideX();
  }

  Widget _buildCheckbox(String label, Map<String, bool> map) {
    return CheckboxListTile(
      title: Text(label),
      value: map[label],
      activeColor: Theme.of(context).primaryColor,
      onChanged: (val) => setState(() => map[label] = val!),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

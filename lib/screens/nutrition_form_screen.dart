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
  bool _isLoading = false;
  GoalType _selectedGoal = GoalType.maintenance;
  final TextEditingController _allergiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentProfile;
    if (profile != null) {
      _allergiesController.text = profile.allergies;
    }
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);

    try {
      final profile = authProvider.currentProfile;
      if (profile == null) return;

      // Mettre à jour le profil avec les nouvelles allergies
      final updated = PatientProfile(
        id: profile.id,
        userId: profile.userId,
        name: profile.name,
        age: profile.age,
        gender: profile.gender,
        weight: profile.weight,
        height: profile.height,
        activityLevel: profile.activityLevel,
        allergies: _allergiesController.text.trim().isEmpty
            ? 'Aucune'
            : _allergiesController.text.trim(),
        medicalConditions: profile.medicalConditions,
        goal: _selectedGoal.label,
      );

      await authProvider.updateProfile(updated);

      await healthProvider.generateAndSavePlan(
        updatedProfile: updated,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan "${_selectedGoal.label}" généré avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentProfile;
    final tdee = profile?.tdee ?? 2000;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau Programme')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info TDEE ────────────────────────────
                if (profile != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Votre TDEE estimé',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$tdee kcal/jour — basé sur votre profil (${profile.activityLevel})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 28),
                const Text(
                  'Choisissez votre objectif',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chaque objectif génère un plan IA unique et indépendant.',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Cartes GoalType ───────────────────────
                ...GoalType.values.asMap().entries.map((entry) {
                  final goal = entry.value;
                  final isSelected = _selectedGoal == goal;
                  final targetCal = tdee + goal.calorieAdjustment;
                  final calLabel = goal.calorieAdjustment == 0
                      ? '$targetCal kcal/jour'
                      : '$targetCal kcal/jour (${goal.calorieAdjustment > 0 ? '+' : ''}${goal.calorieAdjustment} kcal)';

                  return GestureDetector(
                    onTap: () => setState(() => _selectedGoal = goal),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? theme.primaryColor
                              : (isDark ? Colors.white12 : Colors.grey[200]!),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Text(
                            goal.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? theme.primaryColor
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  calLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : Colors.grey,
                                width: 2,
                              ),
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (200 + entry.key * 80).ms).slideX();
                }),

                const SizedBox(height: 24),
                const Text(
                  'Allergies alimentaires',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _allergiesController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Arachides, fruits de mer, gluten...',
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generate,
                    icon: Text(
                      _selectedGoal.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    label: Text(
                      'Générer le plan "${_selectedGoal.label}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms).scale(),
                const SizedBox(height: 40),
              ],
            ),
          ),

          if (_isLoading)
            ModernLoadingOverlay(
              message:
                  'Génération du plan "${_selectedGoal.label}" par l\'IA...',
            ),
        ],
      ),
    );
  }
}

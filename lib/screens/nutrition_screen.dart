import 'package:flutter/material.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/screens/nutrition_form_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  String _selectedDay = "Lundi";
  final List<String> _days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);
    final plan = healthProvider.currentPlan;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Programme Hebdomadaire"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionFormScreen())),
            tooltip: "Modifier les préférences",
          ),
        ],
      ),
      body: healthProvider.isTyping
          ? _buildLoadingState(context)
          : plan == null
              ? _buildEmptyState(context, isDark, healthProvider.planError)
              : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildHeader(plan, isDark).animate().fadeIn().slideY(begin: 0.1, end: 0),
                  ),
                  const SizedBox(height: 24),
                  _buildDaySelector(isDark),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDailySummary(plan.weeklyMeals[_selectedDay] ?? [], isDark)
                            .animate(key: ValueKey(_selectedDay))
                            .fadeIn()
                            .scale(),
                        const SizedBox(height: 24),
                        Text(
                          "Repas du $_selectedDay",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 12),
                        ...(plan.weeklyMeals[_selectedDay] ?? []).asMap().entries.map((entry) {
                          return _buildMealCard(context, entry.value, isDark)
                              .animate(key: ValueKey("$_selectedDay-${entry.key}"))
                              .fadeIn(delay: (300 + entry.key * 100).ms)
                              .slideX();
                        }),
                        const SizedBox(height: 24),
                        Text(
                          "Conseils de santé",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 12),
                        ...plan.tips.map((tip) => _buildTipCard(tip, isDark).animate().fadeIn(delay: 800.ms)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDaySelector(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: ThemeNotifier.primaryGradient)
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
                borderRadius: BorderRadius.circular(25),
                border: isSelected
                    ? null
                    : Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                day,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Génération de votre programme\ntunisien en cours...",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Le modèle IA prépare 21 repas tunisiens pour vous.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              error != null ? Icons.cloud_off_rounded : Icons.no_food_outlined,
              size: 80,
              color: error != null ? Colors.orange : (isDark ? Colors.white38 : Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              error != null ? "Génération impossible" : "Aucun plan généré.",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.orange, fontSize: 14),
                ),
              )
            else
              Text(
                "Créez votre programme nutritionnel\npersonnalisé 100% tunisien.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white60 : Colors.grey[500],
                ),
              ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: ThemeNotifier.primaryGradient),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NutritionFormScreen()),
                ),
                icon: Icon(error != null ? Icons.refresh : Icons.add, color: Colors.white),
                label: Text(
                  error != null ? "Réessayer la génération" : "Créer mon programme",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ).animate().fadeIn().scale(),
      ),
    );
  }

  Widget _buildHeader(NutritionPlan plan, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.transparent
                : const Color(0xFF0D9488).withValues(alpha: 0.06),
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
                      const Color(0xFF10B981).withValues(alpha: 0.15),
                      const Color(0xFF10B981).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  plan.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.description,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey[500],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary(List<Meal> meals, bool isDark) {
    int totalCals = 0;
    double totalProt = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var meal in meals) {
      totalCals += meal.calories;
      totalProt += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "OBJECTIF DU $_selectedDay",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("$totalCals", style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              const Text("kcal", style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroInfo("PROTÉINES", "${totalProt.toStringAsFixed(0)}g", Colors.blue[100]!),
              _buildMacroInfo("GLUCIDES", "${totalCarbs.toStringAsFixed(0)}g", Colors.orange[100]!),
              _buildMacroInfo("LIPIDES", "${totalFat.toStringAsFixed(0)}g", Colors.red[100]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal, bool isDark) {
    IconData typeIcon = Icons.wb_sunny_outlined;
    Color typeColor = Colors.orange;
    if (meal.type.contains("Déjeuner")) {
      typeIcon = Icons.restaurant;
      typeColor = const Color(0xFFEF4444);
    }
    if (meal.type.contains("Collation")) {
      typeIcon = Icons.apple_outlined;
      typeColor = const Color(0xFF10B981);
    }
    if (meal.type.contains("Dîner")) {
      typeIcon = Icons.nightlight_outlined;
      typeColor = const Color(0xFF6366F1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.transparent
                : typeColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showMealDetails(context, meal, isDark),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeColor.withValues(alpha: 0.15),
                  typeColor.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          title: Text(
            meal.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${meal.calories} kcal",
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  meal.type,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.info_outline, size: 16, color: typeColor.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMealDetails(BuildContext context, Meal meal, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0D9488).withValues(alpha: 0.15),
                        const Color(0xFF0D9488).withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant, color: Color(0xFF0D9488)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.name, style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      )),
                      Text(meal.type, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              "COMPOSITION DU REPAS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFF0D9488),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              meal.ingredients.isEmpty
                  ? "Consultez les détails du plat traditionnel tunisien ci-dessus."
                  : meal.ingredients.join(", "),
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.1),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text("ÉNERGIE TOTALE", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Text("${meal.calories} kcal", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(String tip, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFF0D9488).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : const Color(0xFF0D9488).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

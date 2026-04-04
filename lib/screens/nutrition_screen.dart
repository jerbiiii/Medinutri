import 'package:flutter/material.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/health_provider.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
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
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 12),
                        ...(plan.weeklyMeals[_selectedDay] ?? []).asMap().entries.map((entry) {
                          return _buildMealCard(context, entry.value, isDark)
                              .animate(key: ValueKey("$_selectedDay-${entry.key}"))
                              .fadeIn(delay: (300 + entry.key * 100).ms)
                              .slideX();
                        }),
                        const SizedBox(height: 24),
                        const Text(
                          "Conseils de santé",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.blueAccent 
                    : (isDark ? Colors.white10 : Colors.grey[200]),
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Text(
                day,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          const Text(
            "Génération de votre programme\ntunisien en cours...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Le modèle IA prépare 21 repas tunisiens pour vous.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.grey,
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
              color: error != null ? Colors.orange : (isDark ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              error != null ? "Génération impossible" : "Aucun plan généré.",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionFormScreen()),
              ),
              icon: Icon(error != null ? Icons.refresh : Icons.add),
              label: Text(error != null
                  ? "Réessayer la génération"
                  : "Créer mon programme"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.lightGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plan.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.description,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
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
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Text("OBJECTIF DU $_selectedDay", style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("$totalCals", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
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
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal, bool isDark) {
    IconData typeIcon = Icons.wb_sunny_outlined;
    if (meal.type.contains("Déjeuner")) typeIcon = Icons.restaurant;
    if (meal.type.contains("Collation")) typeIcon = Icons.apple_outlined;
    if (meal.type.contains("Dîner")) typeIcon = Icons.nightlight_outlined;

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showMealDetails(context, meal, isDark),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: theme.primaryColor, size: 24),
          ),
          title: Text(
            meal.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${meal.calories} kcal",
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  meal.type,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                Icon(Icons.info_outline, size: 16, color: theme.primaryColor.withValues(alpha: 0.5)),
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
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.restaurant, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(meal.type, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text("COMPOSITION DU REPAS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueAccent)),
            const SizedBox(height: 12),
            Text(
              meal.ingredients.isEmpty ? "Consultez les détails du plat traditionnel tunisien ci-dessus." : meal.ingredients.join(", "),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text("ÉNERGIE TOTALE", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text("${meal.calories} kcal", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
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
        color: isDark ? const Color(0xFF2C2C2C) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

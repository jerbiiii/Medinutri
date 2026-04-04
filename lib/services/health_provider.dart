import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/database_helper.dart';
import 'package:medinutri/services/groq_service.dart';

class HealthProvider with ChangeNotifier {
  User? _currentUser;
  PatientProfile? _currentProfile;
  NutritionPlan? _currentPlan;
  String? _planError;
  final List<Map<String, String>> _messages = [];
  GroqService? _groqService;
  bool _isTyping = false;
  String? _activeConversationId;

  User? get currentUser => _currentUser;
  PatientProfile? get currentProfile => _currentProfile;
  NutritionPlan? get currentPlan => _currentPlan;
  String? get planError => _planError;
  List<Map<String, String>> get messages => _messages;
  bool get isTyping => _isTyping;

  HealthProvider() {
    _groqService = GroqService();
  }

  void updateUser(User? user, PatientProfile? profile) {
    _currentUser = user;
    _currentProfile = profile;
    if (user != null) {
      _loadData();
    } else {
      _messages.clear();
      _currentPlan = null;
      _planError = null;
    }
    notifyListeners();
  }

  Future<void> _loadData() async {
    if (_currentUser == null) return;
    final db = await DatabaseHelper.instance.database;

    final chatData = await db.query(
      'chat_history',
      where: 'user_id = ? AND is_archived = 0',
      whereArgs: [_currentUser!.id],
    );
    _messages.clear();
    _messages.addAll(
      chatData.map(
        (m) => {'role': m['role'] as String, 'content': m['content'] as String},
      ),
    );

    final planData = await db.query(
      'nutrition_plans',
      where: 'user_id = ?',
      whereArgs: [_currentUser!.id],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (planData.isNotEmpty) {
      _currentPlan = NutritionPlan.fromMap(planData.first);
    }
    notifyListeners();
  }

  Future<List<Conversation>> getArchivedConversations() async {
    if (_currentUser == null) return [];
    final db = await DatabaseHelper.instance.database;

    final chatData = await db.query(
      'chat_history',
      where: 'user_id = ? AND is_archived = 1',
      whereArgs: [_currentUser!.id],
      orderBy: 'timestamp DESC',
    );

    final Map<String, List<Map<String, String>>> groupedMessages = {};
    final Map<String, String> titles = {};
    final Map<String, String> firstTimestamps = {};

    for (var m in chatData) {
      final convId = (m['conversation_id'] as String?) ?? "default";
      final title = (m['conversation_title'] as String?) ?? "Ancienne conversation";
      final timestamp = m['timestamp'] as String;

      groupedMessages.putIfAbsent(convId, () => []);
      groupedMessages[convId]!.add({
        'role': m['role'] as String,
        'content': m['content'] as String,
        'timestamp': timestamp,
      });
      titles[convId] = title;
      firstTimestamps.putIfAbsent(convId, () => timestamp);
    }

    return groupedMessages.keys.map((id) {
      return Conversation(
        id: id,
        title: titles[id]!,
        timestamp: DateTime.parse(firstTimestamps[id]!),
        messages: groupedMessages[id]!.reversed.toList(),
      );
    }).toList();
  }

  Future<void> deleteArchivedMessages() async {
    if (_currentUser == null) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'chat_history',
      where: 'user_id = ? AND is_archived = 1',
      whereArgs: [_currentUser!.id],
    );
    notifyListeners();
  }

  Future<void> analyzeSymptoms(String text, {String? systemContext}) async {
    if (_currentUser == null) return;

    _addMessage('user', text);
    _isTyping = true;
    notifyListeners();

    String response;
    if (_groqService != null) {
      response = await _groqService!.getChatResponse(
        _messages,
        customSystemPrompt: systemContext,
      );
    } else {
      await Future.delayed(const Duration(seconds: 2));
      response =
          "Veuillez configurer votre clé Groq pour une analyse complète.";
    }

    _addMessage('assistant', response);
    _isTyping = false;
    notifyListeners();
  }

  Future<void> _addMessage(String role, String content) async {
    _messages.add({'role': role, 'content': content});
    final db = await DatabaseHelper.instance.database;

    _activeConversationId ??= DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('chat_history', {
      'user_id': _currentUser!.id,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'is_archived': 0,
      'conversation_id': _activeConversationId,
    });
    notifyListeners();
  }

  /// Génère un plan nutritionnel 7 jours tunisien via l'IA.
  /// Jamais de données statiques — toujours générées par le modèle.
  Future<void> generateAndSavePlan({PatientProfile? updatedProfile}) async {
    final profileToUse = updatedProfile ?? _currentProfile;
    if (_currentUser == null || profileToUse == null) return;

    _isTyping = true;
    _planError = null;
    _currentPlan = null;
    notifyListeners();

    const breakfasts = [
      'Bssissa au lait chaud', 'Fricassée tunisienne au thon',
      'Lben avec pain tabouna et olives', 'Kalb el louz',
      'Ftayer au fromage et thon', 'Assida zgougou',
      'Makroudh aux dattes et miel',
    ];
    const lunches = [
      'Couscous au poisson (mérou ou dorade)',
      'Ojja merguez aux poivrons',
      'Lablabi aux œufs pochés',
      'Chorba frik au poulet et coriandre',
      'Brick à l\'oeuf, thon et câpres',
      'Kafteji tunisien (légumes frits et œufs)',
      'Marqa poulet aux olives et citron confit',
    ];
    const dinners = [
      'Salade mechouia au thon et câpres',
      'Chakchouka aux légumes et merguez',
      'Merguez grillées, salade tunisienne et pain',
      'Mloukhia à l\'agneau',
      'Borghol aux légumes et menthe',
      'Shorba de légumes du jardin',
      'Tajine malsouka au poulet et fromage',
    ];

    final seed = DateTime.now().millisecondsSinceEpoch % 99999;

    final prompt = '''SEED:$seed
Tu es un chef nutritionniste tunisien expert. Génère un plan nutritionnel hebdomadaire authentiquement TUNISIEN pour le patient suivant :
- Nom : ${profileToUse.name}
- Objectif santé : ${profileToUse.goal}
- Allergies : ${profileToUse.allergies}
- Conditions médicales : ${profileToUse.medicalConditions}
- Niveau d'activité : ${profileToUse.activityLevel}

CONTRAINTES ABSOLUES :
1. 7 jours complets : Lundi, Mardi, Mercredi, Jeudi, Vendredi, Samedi, Dimanche
2. 3 repas par jour : Petit-déjeuner, Déjeuner, Dîner
3. Cuisine 100% tunisienne ou méditerranéenne disponible en Tunisie
4. Exemples de petit-déjeuners : ${breakfasts.join(' | ')}
5. Exemples de déjeuners : ${lunches.join(' | ')}
6. Exemples de dîners : ${dinners.join(' | ')}
7. Varie les plats — aucune répétition sur la semaine
8. Adapte les calories selon l'objectif (${profileToUse.goal})

FORMAT JSON STRICT — Réponds UNIQUEMENT avec ce JSON, sans texte avant ni après :
{"title":"Programme Tunisien 7 jours — ${profileToUse.name}","description":"Plan hebdomadaire cuisine tunisienne authentique adapté à vos besoins.","weeklyMeals":{"Lundi":[{"name":"Nom du plat","type":"Petit-déjeuner","ingredients":["ingredient1","ingredient2","ingredient3"],"preparation":"Description de la préparation en 2-3 phrases.","calories":350,"protein":12.5,"carbs":45.0,"fat":10.0,"prepTime":"10 min"},{"name":"Nom du plat","type":"Déjeuner","ingredients":["ingredient1"],"preparation":"Préparation.","calories":520,"protein":28.0,"carbs":60.0,"fat":14.0,"prepTime":"35 min"},{"name":"Nom du plat","type":"Dîner","ingredients":["ingredient1"],"preparation":"Préparation.","calories":370,"protein":18.0,"carbs":32.0,"fat":12.0,"prepTime":"20 min"}],"Mardi":[{"name":"...","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":320,"protein":10.0,"carbs":42.0,"fat":9.0,"prepTime":"8 min"},{"name":"...","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":500,"protein":26.0,"carbs":58.0,"fat":13.0,"prepTime":"40 min"},{"name":"...","type":"Dîner","ingredients":["..."],"preparation":"...","calories":360,"protein":20.0,"carbs":30.0,"fat":11.0,"prepTime":"25 min"}],"Mercredi":[{"name":"...","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":340,"protein":11.0,"carbs":44.0,"fat":9.5,"prepTime":"12 min"},{"name":"...","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":540,"protein":30.0,"carbs":62.0,"fat":15.0,"prepTime":"50 min"},{"name":"...","type":"Dîner","ingredients":["..."],"preparation":"...","calories":390,"protein":22.0,"carbs":35.0,"fat":13.0,"prepTime":"20 min"}],"Jeudi":[{"name":"...","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":360,"protein":13.0,"carbs":46.0,"fat":10.5,"prepTime":"15 min"},{"name":"...","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":510,"protein":27.0,"carbs":59.0,"fat":13.5,"prepTime":"30 min"},{"name":"...","type":"Dîner","ingredients":["..."],"preparation":"...","calories":380,"protein":19.0,"carbs":33.0,"fat":12.5,"prepTime":"22 min"}],"Vendredi":[{"name":"...","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":330,"protein":11.5,"carbs":43.0,"fat":9.0,"prepTime":"10 min"},{"name":"...","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":560,"protein":32.0,"carbs":65.0,"fat":16.0,"prepTime":"60 min"},{"name":"...","type":"Dîner","ingredients":["..."],"preparation":"...","calories":375,"protein":19.5,"carbs":31.0,"fat":12.0,"prepTime":"18 min"}],"Samedi":[{"name":"...","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":410,"protein":14.0,"carbs":50.0,"fat":12.0,"prepTime":"20 min"},{"name":"...","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":580,"protein":35.0,"carbs":68.0,"fat":17.0,"prepTime":"45 min"},{"name":"...","type":"Dîner","ingredients":["..."],"preparation":"...","calories":400,"protein":22.0,"carbs":36.0,"fat":14.0,"prepTime":"25 min"}],"Dimanche":[{"name":"...","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":345,"protein":12.0,"carbs":44.0,"fat":9.5,"prepTime":"10 min"},{"name":"...","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":530,"protein":29.0,"carbs":62.0,"fat":14.5,"prepTime":"40 min"},{"name":"...","type":"Dîner","ingredients":["..."],"preparation":"...","calories":385,"protein":21.0,"carbs":34.0,"fat":12.5,"prepTime":"20 min"}]},"tips":["Conseil santé 1 spécifique à la cuisine tunisienne","Conseil 2","Conseil 3","Conseil 4"]}''';

    try {
      final response = await _groqService?.getChatResponse(
        [],
        customSystemPrompt: prompt,
      );

      if (response == null || response == '__RATE_LIMITED__' || response == '__ERROR__') {
        _planError = response == '__RATE_LIMITED__'
            ? 'Limite API atteinte. Réessayez dans quelques secondes.'
            : 'Connexion impossible. Vérifiez votre réseau et réessayez.';
        return;
      }

      String jsonStr = response.trim();

      // Strip markdown code blocks if present
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }

      // Extract the outermost JSON object
      final start = jsonStr.indexOf('{');
      final end = jsonStr.lastIndexOf('}');
      if (start >= 0 && end > start) {
        jsonStr = jsonStr.substring(start, end + 1);
      }

      final Map<String, dynamic> planData = jsonDecode(jsonStr);
      final weeklyMealsRaw = planData['weeklyMeals'] as Map?;

      if (weeklyMealsRaw == null || weeklyMealsRaw.length < 7) {
        _planError = 'Plan incomplet reçu (${weeklyMealsRaw?.length ?? 0}/7 jours). Réessayez.';
        return;
      }

      final Map<String, List<Meal>> weeklyMeals = {};
      weeklyMealsRaw.forEach((day, mealsList) {
        if (mealsList is List && mealsList.isNotEmpty) {
          weeklyMeals[day] = mealsList
              .map((m) => Meal.fromMap(Map<String, dynamic>.from(m)))
              .toList();
        }
      });

      _currentPlan = NutritionPlan(
        userId: _currentUser!.id!,
        title: planData['title']?.toString() ??
            'Programme Tunisien — ${profileToUse.name}',
        description: planData['description']?.toString() ??
            'Plan hebdomadaire de cuisine tunisienne authentique.',
        weeklyMeals: weeklyMeals,
        tips: planData['tips'] != null
            ? List<String>.from(planData['tips'])
            : ['Boire 2L d\'eau par jour.', 'Favoriser l\'huile d\'olive.'],
      );

      final db = await DatabaseHelper.instance.database;
      await db.delete('nutrition_plans',
          where: 'user_id = ?', whereArgs: [_currentUser!.id]);
      await db.insert('nutrition_plans', _currentPlan!.toMap());
      _planError = null;
    } catch (e) {
      debugPrint('generateAndSavePlan error: $e');
      _planError = 'Erreur lors du traitement du plan. Réessayez.';
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    if (_currentUser == null || _messages.isEmpty) return;

    final db = await DatabaseHelper.instance.database;

    String title = "Nouvelle conversation";
    if (_messages.isNotEmpty) {
      final firstMsg = _messages.first['content'] ?? "";
      title = firstMsg.length > 30
          ? "${firstMsg.substring(0, 30)}..."
          : firstMsg;

      if (_groqService != null) {
        try {
          final titlePrompt =
              "Génère un titre très court (max 5 mots) résumant cette conversation : $firstMsg";
          final aiTitle = await _groqService!.getChatResponse([
            {'role': 'user', 'content': firstMsg},
          ], customSystemPrompt: titlePrompt);
          if (aiTitle.isNotEmpty && aiTitle.length < 50) {
            title = aiTitle.replaceAll('"', '').trim();
          }
        } catch (_) {}
      }
    }

    final newConvId =
        _activeConversationId ?? DateTime.now().millisecondsSinceEpoch.toString();

    await db.update(
      'chat_history',
      {
        'is_archived': 1,
        'conversation_id': newConvId,
        'conversation_title': title,
      },
      where: 'user_id = ? AND is_archived = 0',
      whereArgs: [_currentUser!.id],
    );

    _messages.clear();
    _activeConversationId = null;
    notifyListeners();
  }
}

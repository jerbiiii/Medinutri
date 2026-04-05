import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/database_helper.dart';
import 'package:medinutri/services/groq_service.dart';
import 'package:sqflite/sqflite.dart';

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

  List<Doctor> _doctors = [];
  bool _isLoadingDoctors = false;

  List<Doctor> get doctors => _doctors;
  bool get isLoadingDoctors => _isLoadingDoctors;

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
      final title =
          (m['conversation_title'] as String?) ?? "Ancienne conversation";
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

    // FIX: était non-awaité → race condition sur la DB
    await _addMessage('user', text);
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

    await _addMessage('assistant', response);
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

  /// Génère un plan nutritionnel 7 jours tunisien via l'IA avec vraie variété.
  Future<void> generateAndSavePlan({PatientProfile? updatedProfile}) async {
    final profileToUse = updatedProfile ?? _currentProfile;
    if (_currentUser == null || profileToUse == null) return;

    _isTyping = true;
    _planError = null;
    _currentPlan = null;
    notifyListeners();

    // FIX: Listes séparées par catégorie + shuffle aléatoire pour variété réelle
    final rng = Random();
    final now = DateTime.now();

    final breakfasts = [
      'Bssissa au lait chaud et huile d\'olive',
      'Fricassée tunisienne au thon, olive et harissa',
      'Lben avec pain tabouna maison et olives noires',
      'Kalb el louz (gâteau aux amandes et miel)',
      'Ftayer au fromage, thon et tomates',
      'Assida zgougou (crème aux pignons de pin)',
      'Makroudh aux dattes et sirop de miel',
      'Ojja aux œufs et légumes grillés',
      'Pain tabouna avec huile d\'olive et zaatar',
      'Bourek au fromage et persil frais',
    ]..shuffle(rng);

    final lunches = [
      'Couscous au poisson (mérou ou dorade) et légumes',
      'Ojja merguez aux poivrons et tomates',
      'Lablabi aux œufs pochés et pain rassis',
      'Chorba frik au poulet et coriandre fraîche',
      'Brick à l\'oeuf, thon, câpres et harissa',
      'Kafteji tunisien (légumes frits et œufs brouillés)',
      'Marqa poulet aux olives vertes et citron confit',
      'Couscous à l\'agneau et légumes de saison',
      'Tajine malsouka au poulet, fromage et herbes',
      'Shorba de légumes du jardin et vermicelle',
    ]..shuffle(rng);

    final dinners = [
      'Salade mechouia au thon, câpres et harissa',
      'Chakchouka aux légumes, poivrons et merguez',
      'Merguez grillées, salade tunisienne fraîche et pain',
      'Mloukhia à l\'agneau avec pain traditionnel',
      'Borghol aux légumes, menthe et citron',
      'Poisson grillé, salade et légumes vapeur',
      'Poulet rôti aux épices tunisiennes et courgettes',
      'Salade de poulpe grillé et légumes marinés',
      'Soupe de légumes tunisienne et croûtons',
      'Tajine de légumes et pois chiches au cumin',
    ]..shuffle(rng);

    // Seed unique combinant timestamp + profil pour forcer la variété
    final seed = now.millisecondsSinceEpoch % 999983;
    final goalCode = profileToUse.goal.hashCode % 100;
    final weightCode = profileToUse.weight.toInt() % 10;

    // Sélectionner 7 options uniques de chaque liste (déjà shufflée)
    final selectedBreakfasts = breakfasts.take(7).toList();
    final selectedLunches = lunches.take(7).toList();
    final selectedDinners = dinners.take(7).toList();

    final prompt =
        '''VARIATION_SEED:$seed|PROFIL_CODE:${goalCode}_${weightCode}|TIMESTAMP:${now.toIso8601String()}

Tu es un chef nutritionniste tunisien expert. Génère un plan nutritionnel UNIQUE et varié pour :
- Nom : ${profileToUse.name}
- Objectif santé : ${profileToUse.goal}
- Allergies : ${profileToUse.allergies}
- Conditions médicales : ${profileToUse.medicalConditions}
- Niveau d'activité : ${profileToUse.activityLevel}
- Poids : ${profileToUse.weight}kg | Taille : ${profileToUse.height}cm

REPAS SUGGÉRÉS (utilise-les dans l'ordre donné, ils sont déjà mélangés pour ce profil) :
Petits-déjeuners (Lundi→Dimanche) : ${selectedBreakfasts.join(' | ')}
Déjeuners (Lundi→Dimanche) : ${selectedLunches.join(' | ')}
Dîners (Lundi→Dimanche) : ${selectedDinners.join(' | ')}

RÈGLES ABSOLUES :
1. 7 jours : Lundi, Mardi, Mercredi, Jeudi, Vendredi, Samedi, Dimanche
2. 3 repas/jour : Petit-déjeuner, Déjeuner, Dîner
3. Utilise EXACTEMENT les plats suggérés ci-dessus dans l'ordre
4. Adapte les calories à l'objectif "${profileToUse.goal}" et au poids ${profileToUse.weight}kg
5. Fournis des ingrédients réels et une préparation détaillée tunisienne authentique

RÉPONDS UNIQUEMENT EN JSON VALIDE (pas de texte avant ni après) :
{"title":"Programme Tunisien 7 jours — ${profileToUse.name}","description":"Plan hebdomadaire cuisine tunisienne authentique personnalisé.","weeklyMeals":{"Lundi":[{"name":"${selectedBreakfasts[0]}","type":"Petit-déjeuner","ingredients":["ingredient1","ingredient2","ingredient3"],"preparation":"Préparation détaillée en 2-3 phrases.","calories":350,"protein":12.0,"carbs":45.0,"fat":10.0,"prepTime":"10 min"},{"name":"${selectedLunches[0]}","type":"Déjeuner","ingredients":["ingredient1","ingredient2"],"preparation":"Préparation.","calories":520,"protein":28.0,"carbs":60.0,"fat":14.0,"prepTime":"35 min"},{"name":"${selectedDinners[0]}","type":"Dîner","ingredients":["ingredient1","ingredient2"],"preparation":"Préparation.","calories":370,"protein":18.0,"carbs":32.0,"fat":12.0,"prepTime":"20 min"}],"Mardi":[{"name":"${selectedBreakfasts[1]}","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":320,"protein":10.0,"carbs":42.0,"fat":9.0,"prepTime":"8 min"},{"name":"${selectedLunches[1]}","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":500,"protein":26.0,"carbs":58.0,"fat":13.0,"prepTime":"40 min"},{"name":"${selectedDinners[1]}","type":"Dîner","ingredients":["..."],"preparation":"...","calories":360,"protein":20.0,"carbs":30.0,"fat":11.0,"prepTime":"25 min"}],"Mercredi":[{"name":"${selectedBreakfasts[2]}","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":340,"protein":11.0,"carbs":44.0,"fat":9.5,"prepTime":"12 min"},{"name":"${selectedLunches[2]}","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":540,"protein":30.0,"carbs":62.0,"fat":15.0,"prepTime":"50 min"},{"name":"${selectedDinners[2]}","type":"Dîner","ingredients":["..."],"preparation":"...","calories":390,"protein":22.0,"carbs":35.0,"fat":13.0,"prepTime":"20 min"}],"Jeudi":[{"name":"${selectedBreakfasts[3]}","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":360,"protein":13.0,"carbs":46.0,"fat":10.5,"prepTime":"15 min"},{"name":"${selectedLunches[3]}","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":510,"protein":27.0,"carbs":59.0,"fat":13.5,"prepTime":"30 min"},{"name":"${selectedDinners[3]}","type":"Dîner","ingredients":["..."],"preparation":"...","calories":380,"protein":19.0,"carbs":33.0,"fat":12.5,"prepTime":"22 min"}],"Vendredi":[{"name":"${selectedBreakfasts[4]}","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":330,"protein":11.5,"carbs":43.0,"fat":9.0,"prepTime":"10 min"},{"name":"${selectedLunches[4]}","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":560,"protein":32.0,"carbs":65.0,"fat":16.0,"prepTime":"60 min"},{"name":"${selectedDinners[4]}","type":"Dîner","ingredients":["..."],"preparation":"...","calories":375,"protein":19.5,"carbs":31.0,"fat":12.0,"prepTime":"18 min"}],"Samedi":[{"name":"${selectedBreakfasts[5]}","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":410,"protein":14.0,"carbs":50.0,"fat":12.0,"prepTime":"20 min"},{"name":"${selectedLunches[5]}","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":580,"protein":35.0,"carbs":68.0,"fat":17.0,"prepTime":"45 min"},{"name":"${selectedDinners[5]}","type":"Dîner","ingredients":["..."],"preparation":"...","calories":400,"protein":22.0,"carbs":36.0,"fat":14.0,"prepTime":"25 min"}],"Dimanche":[{"name":"${selectedBreakfasts[6]}","type":"Petit-déjeuner","ingredients":["..."],"preparation":"...","calories":345,"protein":12.0,"carbs":44.0,"fat":9.5,"prepTime":"10 min"},{"name":"${selectedLunches[6]}","type":"Déjeuner","ingredients":["..."],"preparation":"...","calories":530,"protein":29.0,"carbs":62.0,"fat":14.5,"prepTime":"40 min"},{"name":"${selectedDinners[6]}","type":"Dîner","ingredients":["..."],"preparation":"...","calories":385,"protein":21.0,"carbs":34.0,"fat":12.5,"prepTime":"20 min"}]},"tips":["Conseil santé tunisien spécifique 1 adapté à ${profileToUse.goal}","Conseil 2","Conseil 3","Conseil 4"]}''';

    try {
      final response = await _groqService?.getChatResponse(
        [],
        customSystemPrompt: prompt,
      );

      if (response == null ||
          response == '__RATE_LIMITED__' ||
          response == '__ERROR__') {
        _planError = response == '__RATE_LIMITED__'
            ? 'Limite API atteinte. Réessayez dans quelques secondes.'
            : 'Connexion impossible. Vérifiez votre réseau et réessayez.';
        return;
      }

      String jsonStr = response.trim();

      // Nettoyer les blocs markdown si présents
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }

      // Extraire l'objet JSON valide
      final start = jsonStr.indexOf('{');
      final end = jsonStr.lastIndexOf('}');
      if (start >= 0 && end > start) {
        jsonStr = jsonStr.substring(start, end + 1);
      }

      final Map<String, dynamic> planData = jsonDecode(jsonStr);
      final weeklyMealsRaw = planData['weeklyMeals'] as Map?;

      if (weeklyMealsRaw == null || weeklyMealsRaw.length < 7) {
        _planError =
            'Plan incomplet reçu (${weeklyMealsRaw?.length ?? 0}/7 jours). Réessayez.';
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
        goalType: GoalType.fromString(profileToUse.goal),
        dailyCaloricTarget: profileToUse.tdee,
        title:
            planData['title']?.toString() ??
            'Programme Tunisien — ${profileToUse.name}',
        description:
            planData['description']?.toString() ??
            'Plan hebdomadaire de cuisine tunisienne authentique.',
        weeklyMeals: weeklyMeals,
        tips: planData['tips'] != null
            ? List<String>.from(planData['tips'])
            : ['Boire 2L d\'eau par jour.', 'Favoriser l\'huile d\'olive.'],
      );

      final db = await DatabaseHelper.instance.database;
      // Supprimer l'ancien plan avant d'insérer le nouveau
      await db.delete(
        'nutrition_plans',
        where: 'user_id = ?',
        whereArgs: [_currentUser!.id],
      );
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
        _activeConversationId ??
        DateTime.now().millisecondsSinceEpoch.toString();

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

  Future<void> loadOrGenerateDoctors({bool forceRefresh = false}) async {
    if (_doctors.isNotEmpty && !forceRefresh) return;
    _isLoadingDoctors = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;

      if (!forceRefresh) {
        final rows = await db.query('ai_doctors');
        if (rows.isNotEmpty) {
          final firstDate = DateTime.tryParse(
            rows.first['created_at'] as String? ?? '',
          );
          if (firstDate != null &&
              DateTime.now().difference(firstDate).inDays < 7) {
            _doctors = rows.map((r) => Doctor.fromMap(r)).toList();
            _isLoadingDoctors = false;
            notifyListeners();
            return;
          }
        }
      }

      final symptomContext = _messages.isNotEmpty
          ? 'Basé sur les derniers symptômes du patient : ${_messages.last['content']}'
          : 'App généraliste de télémédecine';

      final prompt =
          '''Génère une liste de 8 médecins fictifs pour une app de télémédecine tunisienne.
$symptomContext
 
Règles :
- Noms maghrébins/français réalistes
- Spécialités variées
- Genre mixte (4 hommes, 4 femmes)
- Notes réalistes entre 4.5 et 5.0
 
FORMAT JSON STRICT — UNIQUEMENT CE JSON :
{"doctors":[{"id":"1","name":"Dr. Prénom Nom","specialty":"Spécialité médicale","rating":"4.8","gender":"male"},{"id":"2","name":"Dr. Prénom Nom","specialty":"Spécialité","rating":"4.9","gender":"female"}]}''';

      final response = await _groqService?.getChatResponse(
        [],
        customSystemPrompt: prompt,
      );

      if (response == null ||
          response.startsWith('__') ||
          response.startsWith('Erreur')) {
        _isLoadingDoctors = false;
        notifyListeners();
        return;
      }

      String json = response.trim();
      final start = json.indexOf('{');
      final end = json.lastIndexOf('}');
      if (start >= 0 && end > start) json = json.substring(start, end + 1);

      final data = jsonDecode(json) as Map<String, dynamic>;
      final doctorsList = (data['doctors'] as List?) ?? [];

      final now = DateTime.now().toIso8601String();
      final generated = <Doctor>[];

      // FIX: vider la table avant de réinsérer
      await db.delete('ai_doctors');

      for (final d in doctorsList) {
        final map = Map<String, dynamic>.from(d as Map);
        final gender = map['gender'] as String? ?? 'male';
        final doctorId = map['id'] as String? ?? '${generated.length + 1}';
        final imageUrl =
            'https://i.pravatar.cc/150?u=doctor_${doctorId}_$gender';

        final doctor = Doctor(
          id: doctorId,
          name: map['name'] as String,
          specialty: map['specialty'] as String,
          rating: map['rating'] as String? ?? '4.5',
          imageUrl: imageUrl,
          gender: gender,
        );
        generated.add(doctor);

        // FIX: inclure doctor_id explicitement dans l'insert
        // (séparé de id qui est l'auto-increment SQLite)
        await db.insert('ai_doctors', {
          'doctor_id': doctorId, // ← colonne doctor_id = string IA
          'name': doctor.name,
          'specialty': doctor.specialty,
          'rating': doctor.rating,
          'image_url': doctor.imageUrl,
          'gender': doctor.gender,
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      _doctors = generated;
    } catch (e) {
      debugPrint('loadOrGenerateDoctors error: $e');
    } finally {
      _isLoadingDoctors = false;
      notifyListeners();
    }
  }

  Future<String> generateDiagnosticSummary() async {
    final profile = _currentProfile;
    if (profile == null) return 'Complétez votre profil pour un diagnostic.';

    if (_messages.isEmpty) {
      return 'Aucune consultation récente. Décrivez vos symptômes au Dr. Vitality.';
    }

    final recentMessages = _messages.length > 8
        ? _messages.sublist(_messages.length - 8)
        : List<Map<String, String>>.from(_messages);

    final summaryPrompt =
        'Résume en UNE phrase courte (max 20 mots) le principal problème de santé '
        'évoqué dans cette conversation. Commence par le problème, pas par "Le patient...".';

    final summary = await _groqService?.getChatResponse(
      recentMessages,
      customSystemPrompt: summaryPrompt,
    );

    if (summary == null ||
        summary.startsWith('__') ||
        summary.startsWith('Erreur')) {
      return 'Dernière consultation disponible. Une consultation vidéo est recommandée.';
    }
    return summary.replaceAll('"', '').trim();
  }

  Future<String> analyzeForVoiceConsultation(
    String text,
    List<Map<String, String>> localHistory,
    String doctorPersona,
  ) async {
    localHistory.add({'role': 'user', 'content': 'Patient: $text'});

    final response = await _groqService?.getChatResponse(
      localHistory,
      customSystemPrompt: doctorPersona,
    );

    localHistory.add({'role': 'assistant', 'content': response ?? ""});
    return response ?? "";
  }
}

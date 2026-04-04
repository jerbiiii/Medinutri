import 'dart:convert';

class User {
  final int? id;
  final String username;
  final String? passwordHash;

  User({this.id, required this.username, this.passwordHash});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
    );
  }
}

class PatientProfile {
  final int? id;
  final int userId;
  final String name;
  final int age;
  final String gender;
  final double weight;
  final double height;
  final String activityLevel; // e.g., Sedentary, Moderate, Active, Very Active
  final String allergies; 
  final String medicalConditions;
  final String goal; // e.g., Weight Loss, Muscle Gain, Maintenance

  PatientProfile({
    this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    this.activityLevel = "Modérée",
    this.allergies = "Aucune",
    this.medicalConditions = "Aucune",
    this.goal = "Équilibre alimentaire",
  });

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiStatus {
    if (bmi < 18.5) return 'Insuffisance pondérale';
    if (bmi < 25) return 'Poids normal';
    if (bmi < 30) return 'Surpoids';
    return 'Obésité';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'activity_level': activityLevel,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'goal': goal,
    };
  }

  factory PatientProfile.fromMap(Map<String, dynamic> map) {
    return PatientProfile(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      weight: map['weight'],
      height: map['height'],
      activityLevel: map['activity_level'] ?? "Modérée",
      allergies: map['allergies'] ?? "Aucune",
      medicalConditions: map['medical_conditions'] ?? "Aucune",
      goal: map['goal'] ?? "Équilibre alimentaire",
    );
  }
}

class NutritionPlan {
  final int? id;
  final int userId;
  final String title;
  final String description;
  final Map<String, List<Meal>> weeklyMeals; // e.g. {"Lundi": [Meal1, Meal2], ...}
  final List<String> tips;

  NutritionPlan({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.weeklyMeals,
    required this.tips,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> mealsMap = {};
    weeklyMeals.forEach((day, meals) {
      mealsMap[day] = meals.map((m) => m.toMap()).toList();
    });

    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'meals_json': jsonEncode(mealsMap),
      'tips_json': jsonEncode(tips),
    };
  }

  factory NutritionPlan.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> decodedMeals = jsonDecode(map['meals_json']);
    final Map<String, List<Meal>> weeklyMeals = {};
    
    decodedMeals.forEach((day, mealsList) {
      weeklyMeals[day] = (mealsList as List)
          .map((m) => Meal.fromMap(m))
          .toList();
    });

    return NutritionPlan(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      weeklyMeals: weeklyMeals,
      tips: List<String>.from(jsonDecode(map['tips_json'])),
    );
  }
}

class Meal {
  final String name;
  final String type;
  final List<String> ingredients;
  final String preparation;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String prepTime;

  Meal({
    required this.name,
    required this.type,
    required this.ingredients,
    required this.preparation,
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.prepTime = "N/A",
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'ingredients': ingredients,
      'preparation': preparation,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'prepTime': prepTime,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      name: map['name'],
      type: map['type'],
      ingredients: List<String>.from(map['ingredients']),
      preparation: map['preparation'],
      calories: map['calories'] ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      prepTime: map['prepTime'] ?? "N/A",
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String rating;
  final String image;
  final String gender; // 'male' or 'female'
  final String? voiceId;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.image,
    required this.gender,
    this.voiceId,
  });
}

class Conversation {
  final String id;
  final String title;
  final DateTime timestamp;
  final List<Map<String, String>> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.messages,
  });
}

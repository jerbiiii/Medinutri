import 'dart:convert';

// ─────────────────────────────────────────────────────────
//  GOAL TYPE
// ─────────────────────────────────────────────────────────
enum GoalType {
  weightLoss,
  weightGain,
  maintenance,
  energy,
  rebalancing;

  String get label => switch (this) {
    GoalType.weightLoss => 'Perte de poids',
    GoalType.weightGain => 'Prise de masse',
    GoalType.maintenance => 'Équilibre alimentaire',
    GoalType.energy => "Plus d'énergie",
    GoalType.rebalancing => 'Rééquilibrage',
  };

  String get emoji => switch (this) {
    GoalType.weightLoss => '🏃',
    GoalType.weightGain => '💪',
    GoalType.maintenance => '⚖️',
    GoalType.energy => '⚡',
    GoalType.rebalancing => '🥗',
  };

  int get calorieAdjustment => switch (this) {
    GoalType.weightLoss => -500,
    GoalType.weightGain => 400,
    GoalType.maintenance => 0,
    GoalType.energy => 100,
    GoalType.rebalancing => -100,
  };

  static GoalType fromString(String s) => GoalType.values.firstWhere(
    (e) => e.name == s,
    orElse: () => GoalType.maintenance,
  );
}

// ─────────────────────────────────────────────────────────
//  USER
// ─────────────────────────────────────────────────────────
class User {
  final String? id;
  final String username;

  User({this.id, required this.username});

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    username: map['username'],
  );
}

// ─────────────────────────────────────────────────────────
//  PATIENT PROFILE
// ─────────────────────────────────────────────────────────
class PatientProfile {
  final String? id;
  final String userId;
  final String name;
  final int age;
  final String gender;
  final double weight;
  final double height;
  final String activityLevel;
  final String allergies;
  final String medicalConditions;
  final String goal;
  final String? photoPath;

  PatientProfile({
    this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    this.activityLevel = 'Modérée',
    this.allergies = 'Aucune',
    this.medicalConditions = 'Aucune',
    this.goal = 'Équilibre alimentaire',
    this.photoPath,
  });

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiStatus {
    if (bmi < 18.5) return 'Insuffisance pondérale';
    if (bmi < 25) return 'Poids normal';
    if (bmi < 30) return 'Surpoids';
    return 'Obésité';
  }

  double get bmr {
    final base = 10 * weight + 6.25 * height - 5 * age;
    return gender == 'Homme' ? base + 5 : base - 161;
  }

  int get tdee {
    final multiplier = switch (activityLevel) {
      'Sédentaire' => 1.2,
      'Modérée' => 1.375,
      'Active' => 1.55,
      'Très Active' => 1.725,
      _ => 1.375,
    };
    return (bmr * multiplier).round();
  }

  Map<String, dynamic> toMap() => {
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
    'photo_path': photoPath,
  };

  factory PatientProfile.fromMap(Map<String, dynamic> map) => PatientProfile(
    id: map['id']?.toString(),
    userId: map['user_id']?.toString() ?? '',
    name: map['name'],
    age: map['age'],
    gender: map['gender'],
    weight: (map['weight'] as num).toDouble(),
    height: (map['height'] as num).toDouble(),
    activityLevel: map['activity_level'] ?? 'Modérée',
    allergies: map['allergies'] ?? 'Aucune',
    medicalConditions: map['medical_conditions'] ?? 'Aucune',
    goal: map['goal'] ?? 'Équilibre alimentaire',
    photoPath: map['photo_path'] as String?,
  );

  /// Copie avec photoPath mis à jour
  PatientProfile copyWithPhoto(String? newPhotoPath) => PatientProfile(
    id: id,
    userId: userId,
    name: name,
    age: age,
    gender: gender,
    weight: weight,
    height: height,
    activityLevel: activityLevel,
    allergies: allergies,
    medicalConditions: medicalConditions,
    goal: goal,
    photoPath: newPhotoPath,
  );
}

// ─────────────────────────────────────────────────────────
//  NUTRITION PLAN
// ─────────────────────────────────────────────────────────
class NutritionPlan {
  final String? id;
  final String userId;
  final GoalType goalType;
  final int dailyCaloricTarget;
  final String title;
  final String description;
  final Map<String, List<Meal>> weeklyMeals;
  final List<String> tips;
  final DateTime createdAt;

  NutritionPlan({
    this.id,
    required this.userId,
    required this.goalType,
    required this.dailyCaloricTarget,
    required this.title,
    required this.description,
    required this.weeklyMeals,
    required this.tips,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> mealsMap = {};
    weeklyMeals.forEach((day, meals) {
      mealsMap[day] = meals.map((m) => m.toMap()).toList();
    });
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'goal_type': goalType.name,
      'daily_caloric_target': dailyCaloricTarget,
      'title': title,
      'description': description,
      'meals_json': jsonEncode(mealsMap),
      'tips_json': jsonEncode(tips),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NutritionPlan.fromMap(Map<String, dynamic> map) {
    final decodedMeals = jsonDecode(map['meals_json'] as String) as Map;
    final weeklyMeals = <String, List<Meal>>{};
    decodedMeals.forEach((day, mealsList) {
      weeklyMeals[day as String] = (mealsList as List)
          .map((m) => Meal.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    });
    return NutritionPlan(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      goalType: GoalType.fromString(
        map['goal_type'] as String? ?? 'maintenance',
      ),
      dailyCaloricTarget: map['daily_caloric_target'] as int? ?? 2000,
      title: map['title'] as String,
      description: map['description'] as String,
      weeklyMeals: weeklyMeals,
      tips: List<String>.from(jsonDecode(map['tips_json'] as String) as List),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MEAL
// ─────────────────────────────────────────────────────────
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

  const Meal({
    required this.name,
    required this.type,
    required this.ingredients,
    required this.preparation,
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.prepTime = 'N/A',
  });

  Map<String, dynamic> toMap() => {
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

  factory Meal.fromMap(Map<String, dynamic> map) => Meal(
    name: map['name'] as String,
    type: map['type'] as String,
    ingredients: List<String>.from(map['ingredients'] as List),
    preparation: map['preparation'] as String,
    calories: map['calories'] as int? ?? 0,
    protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
    carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
    fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
    prepTime: map['prepTime'] as String? ?? 'N/A',
  );
}

// ─────────────────────────────────────────────────────────
//  DOCTOR
// ─────────────────────────────────────────────────────────
class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String rating;
  final String imageUrl;
  final String gender;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.imageUrl,
    required this.gender,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'specialty': specialty,
    'rating': rating,
    'image_url': imageUrl,
    'gender': gender,
  };

  factory Doctor.fromMap(Map<String, dynamic> map) {
    final rawId = map['doctor_id'] ?? map['id'];
    return Doctor(
      id: rawId?.toString() ?? '1',
      name: map['name'] as String,
      specialty: map['specialty'] as String,
      rating: (map['rating'] ?? '4.5') as String,
      imageUrl: map['image_url'] as String? ?? map['imageUrl'] as String? ?? '',
      gender: (map['gender'] ?? 'male') as String,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  CONVERSATION
// ─────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────
//  MEDICATION
// ─────────────────────────────────────────────────────────
class Medication {
  final String? id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String notes;
  final String color;
  final String icon;
  final bool isActive;
  final DateTime? createdAt;

  Medication({
    this.id,
    required this.userId,
    required this.name,
    this.dosage = '',
    this.frequency = 'daily',
    this.times = const ['08:00'],
    DateTime? startDate,
    this.endDate,
    this.notes = '',
    this.color = '#0D9488',
    this.icon = 'medication',
    this.isActive = true,
    this.createdAt,
  }) : startDate = startDate ?? DateTime.now();

  String get frequencyLabel => switch (frequency) {
    'daily' => 'Chaque jour',
    'twice_daily' => '2 fois/jour',
    'three_daily' => '3 fois/jour',
    'weekly' => 'Chaque semaine',
    'as_needed' => 'Si nécessaire',
    _ => frequency,
  };

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'times_json': jsonEncode(times),
    'start_date': startDate.toIso8601String().split('T').first,
    'end_date': endDate?.toIso8601String().split('T').first,
    'notes': notes,
    'color': color,
    'icon': icon,
    'is_active': isActive,
  };

  factory Medication.fromMap(Map<String, dynamic> map) {
    List<String> parsedTimes = ['08:00'];
    try {
      final raw = map['times_json'];
      if (raw is String && raw.isNotEmpty) {
        parsedTimes = List<String>.from(jsonDecode(raw));
      }
    } catch (_) {}

    return Medication(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      name: map['name'] as String,
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? 'daily',
      times: parsedTimes,
      startDate: DateTime.tryParse(map['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: map['end_date'] != null ? DateTime.tryParse(map['end_date'].toString()) : null,
      notes: map['notes'] as String? ?? '',
      color: map['color'] as String? ?? '#0D9488',
      icon: map['icon'] as String? ?? 'medication',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MEDICATION LOG
// ─────────────────────────────────────────────────────────
class MedicationLog {
  final String? id;
  final String medicationId;
  final String userId;
  final String scheduledTime;
  final String status; // 'taken', 'skipped', 'postponed'
  final DateTime takenAt;

  MedicationLog({
    this.id,
    required this.medicationId,
    required this.userId,
    required this.scheduledTime,
    this.status = 'taken',
    DateTime? takenAt,
  }) : takenAt = takenAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'medication_id': medicationId,
    'user_id': userId,
    'scheduled_time': scheduledTime,
    'status': status,
    'taken_at': takenAt.toIso8601String(),
  };

  factory MedicationLog.fromMap(Map<String, dynamic> map) => MedicationLog(
    id: map['id']?.toString(),
    medicationId: map['medication_id']?.toString() ?? '',
    userId: map['user_id']?.toString() ?? '',
    scheduledTime: map['scheduled_time'] as String? ?? '',
    status: map['status'] as String? ?? 'taken',
    takenAt: DateTime.tryParse(map['taken_at']?.toString() ?? '') ?? DateTime.now(),
  );
}

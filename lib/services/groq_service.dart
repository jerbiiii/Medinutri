import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";

  static const String _chatModel = "llama-3.1-8b-instant";
  static const String _nutritionModel = "llama-3.3-70b-versatile";

  GroqService();

  Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    String? customSystemPrompt,
  }) async {
    final bool isNutritionGeneration =
        customSystemPrompt != null &&
        customSystemPrompt.contains('weeklyMeals');

    final model = isNutritionGeneration ? _nutritionModel : _chatModel;
    // FIX: température plus élevée pour la nutrition → plus de variété
    final temperature = isNutritionGeneration ? 1.0 : 0.7;
    final maxTokens = isNutritionGeneration ? 8192 : 1024;

    final String systemPrompt =
        customSystemPrompt ??
        "Tu es le Dr. Vitality, un médecin IA expert en télémédecine et nutrition. "
            "Ta mission est d'analyser les symptômes de l'utilisateur avec bienveillance. "
            "Donne une évaluation préliminaire claire et suggère une consultation si nécessaire. "
            "Si l'utilisateur a des problèmes de poids (obésité ou maigreur), propose explicitement un plan nutritionnel. "
            "Réponds de manière concise, réactive et professionnelle.";

    // Corps de la requête
    final Map<String, dynamic> requestBody = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    // FIX: response_format json_object seulement pour la nutrition
    // (évite les réponses non-JSON pour le chat normal)
    if (isNutritionGeneration) {
      requestBody['response_format'] = {'type': 'json_object'};
    }

    // Retry logic: jusqu'à 3 tentatives avec backoff exponentiel
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {
                'Authorization': 'Bearer $_apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 90));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        } else if (response.statusCode == 429) {
          if (attempt < 3) {
            final waitSeconds = pow(2, attempt).toInt();
            await Future.delayed(Duration(seconds: waitSeconds));
            continue;
          }
          return "__RATE_LIMITED__";
        } else {
          debugPrint(
            "Groq API Error [Attempt $attempt]: ${response.statusCode} - ${response.body}",
          );
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          return "Désolé, je rencontre une erreur de connexion (Code: ${response.statusCode}).";
        }
      } catch (e) {
        debugPrint("Groq Service Exception [Attempt $attempt]: $e");
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return "Une erreur est survenue lors de la communication avec l'IA.";
      }
    }
    return "__ERROR__";
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey =
      "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";
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";

  // More capable model with larger context window
  static const String _chatModel = "llama-3.1-8b-instant";
  static const String _nutritionModel = "llama-3.3-70b-versatile";

  GroqService();

  Future<String> getChatResponse(
    List<Map<String, String>> messages, {
    String? customSystemPrompt,
  }) async {
    final bool isNutritionGeneration = customSystemPrompt != null &&
        customSystemPrompt.contains('weeklyMeals');

    final model = isNutritionGeneration ? _nutritionModel : _chatModel;
    final temperature = isNutritionGeneration ? 0.85 : 0.7;
    final maxTokens = isNutritionGeneration ? 8192 : 1024;

    final String systemPrompt = customSystemPrompt ??
        "Tu es le Dr. Vitality, un médecin IA expert en télémédecine et nutrition. "
        "Ta mission est d'analyser les symptômes de l'utilisateur avec bienveillance. "
        "Donne une évaluation préliminaire claire et suggère une consultation si nécessaire. "
        "Si l'utilisateur a des problèmes de poids (obésité ou maigreur), propose explicitement un plan nutritionnel. "
        "Réponds de manière concise, réactive et professionnelle.";

    // Retry logic: up to 3 attempts with exponential backoff
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {
                'Authorization': 'Bearer $_apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  ...messages,
                ],
                'temperature': temperature,
                'max_tokens': maxTokens,
                'response_format': isNutritionGeneration
                    ? {'type': 'json_object'}
                    : null,
              }..removeWhere((key, value) => value == null)),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        } else if (response.statusCode == 429) {
          // Rate limit — wait before retry
          if (attempt < 3) {
            final waitSeconds = pow(2, attempt).toInt();
            await Future.delayed(Duration(seconds: waitSeconds));
            continue;
          }
          return "__RATE_LIMITED__";
        } else {
          print("Groq API Error [Attempt $attempt]: ${response.statusCode} - ${response.body}");
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          return "Désolé, je rencontre une erreur de connexion (Code: ${response.statusCode}).";
        }
      } catch (e) {
        print("Groq Service Exception [Attempt $attempt]: $e");
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

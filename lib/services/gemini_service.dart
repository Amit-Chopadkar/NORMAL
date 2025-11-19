import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static GenerativeModel? _cachedModel;

  static GenerativeModel _model() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Gemini API key is missing. Pass --dart-define=GEMINI_API_KEY=your_key when running the app.',
      );
    }

    _cachedModel ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );

    return _cachedModel!;
  }

  static Future<String> generateSafetyInsights(String prompt) async {
    try {
      final model = _model();
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw Exception('Gemini returned an empty response');
      }

      return text.trim();
    } on StateError catch (e) {
      throw Exception('Gemini API key not configured: ${e.message}');
    } catch (e) {
      throw Exception('Gemini API error: $e');
    }
  }
}


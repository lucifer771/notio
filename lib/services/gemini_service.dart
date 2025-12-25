import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // ⚠️ REPLACE THIS WITH YOUR OWN VALID API KEY
  // Get one here: https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyCe4pU-DRkOjWqT4sSv9lzLK4xClIly1lg';

  late GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Latest fast model
      apiKey: _apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      ],
    );
  }

  Stream<GenerateContentResponse> generateStream(String prompt) {
    final content = [Content.text(prompt)];
    return _model.generateContentStream(content);
  }
}

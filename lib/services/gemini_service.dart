import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ REPLACE THIS WITH YOUR OWN VALID API KEY
  // Get one here: https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyCe4pU-DRkOjWqT4sSv9lzLK4xClIly1lg';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  GeminiService();

  Stream<String> generateStream(String prompt) async* {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Extract the text from the response structure
        // structure: candidates[0].content.parts[0].text
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          yield text; // Yield the full text as a single "chunk"
        }
      } else {
        throw Exception(
            'Failed to generate content: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling Gemini API: $e');
    }
  }
}

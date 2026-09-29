import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiProductResult {
  final String categoryName;
  final String description;
  final double price;
  final String unitQty;
  final String unitType;

  GeminiProductResult({
    required this.categoryName,
    required this.description,
    required this.price,
    required this.unitQty,
    required this.unitType,
  });

  factory GeminiProductResult.fromJson(Map<String, dynamic> json) {
    return GeminiProductResult(
      categoryName: (json['category'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      price: double.tryParse((json['price'] ?? '0').toString()) ?? 0.0,
      unitQty: (json['unitQty'] ?? '1').toString().trim(),
      unitType: (json['unitType'] ?? 'kg').toString().trim(),
    );
  }
}

class GeminiService {
  /// Model candidates tried in order — 3.8 Flash first as user requested
  static const List<String> _candidates = [
    'v1beta/models/gemini-3.8-flash:generateContent',
    'v1beta/models/gemini-3.5-flash:generateContent',
    'v1beta/models/gemini-3.5-flash-lite:generateContent',
    'v1beta/models/gemini-2.5-flash:generateContent',
    'v1beta/models/gemini-2.5-flash-preview-05-20:generateContent',
    'v1beta/models/gemini-2.5-flash-preview-04-17:generateContent',
    'v1beta/models/gemini-2.0-flash:generateContent',
    'v1beta/models/gemini-2.0-flash-exp:generateContent',
    'v1beta/models/gemini-1.5-flash-latest:generateContent',
    'v1beta/models/gemini-1.5-flash:generateContent',
    'v1/models/gemini-2.5-flash:generateContent',
    'v1/models/gemini-2.0-flash:generateContent',
  ];

  static Future<GeminiProductResult> generateProductDetails({
    required String productName,
    required List<String> availableCategories,
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Gemini API key లేదు. Settings లో add చేయండి.');
    }

    final cats = availableCategories.isEmpty
        ? 'Groceries, Snacks, Beverages, Household, Personal Care, Dairy, Spices'
        : availableCategories.join(', ');

    final prompt =
        'You are an AI assistant for an Indian Kirana grocery store.\n'
        'Product name: "$productName"\n'
        'Store categories: $cats\n\n'
        'Return ONLY valid JSON (no markdown, no explanation):\n'
        '{"category":"<pick from categories or suggest new>","description":"<1-2 sentence product description>","price":<price in INR as number>,"unitQty":"<number like 1 or 500>","unitType":"<kg/g/L/ml/Piece/Packet/Dozen/Box>"}';

    Exception? lastError;

    for (final path in _candidates) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/$path?key=${apiKey.trim()}',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.2,
              'maxOutputTokens': 300,
            }
          }),
        );

        debugPrint('Gemini [$path] → ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final String rawText =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

          if (rawText.isNotEmpty) {
            String clean = rawText.trim();
            final s = clean.indexOf('{');
            final e = clean.lastIndexOf('}');
            if (s >= 0 && e > s) clean = clean.substring(s, e + 1);

            final jsonMap = jsonDecode(clean);
            debugPrint('✅ Gemini success with: $path');
            return GeminiProductResult.fromJson(jsonMap);
          }
        } else if (response.statusCode == 404 || response.statusCode == 400) {
          lastError = Exception('Model not found (${response.statusCode})');
          continue;
        } else {
          lastError =
              Exception('API Error (${response.statusCode}): ${response.body}');
        }
      } catch (ex) {
        debugPrint('Gemini exception [$path]: $ex');
        lastError = Exception(ex.toString());
      }
    }

    throw lastError ??
        Exception(
          'Gemini AI పని చేయలేదు.\n'
          'API key check చేయండి: https://aistudio.google.com/app/apikey',
        );
  }
}

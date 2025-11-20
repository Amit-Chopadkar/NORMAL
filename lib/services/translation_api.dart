import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Lightweight wrapper around the free google translate web endpoint.
/// This keeps us within the user's "free API" requirement while remaining
/// dependency-light. The endpoint is undocumented and rate-limited, so we
/// throttle our calls and cache the responses at the LocalizationService level.
class TranslationApi {
  static const String _endpoint =
      'https://translate.googleapis.com/translate_a/single';
  static const Duration _throttle = Duration(milliseconds: 400);
  static DateTime? _lastInvocation;

  static Future<String> translate({
    required String text,
    required String target,
    String source = 'en',
  }) async {
    if (text.trim().isEmpty || target == source) {
      return text;
    }

    final now = DateTime.now();
    if (_lastInvocation != null) {
      final elapsed = now.difference(_lastInvocation!);
      if (elapsed < _throttle) {
        await Future.delayed(_throttle - elapsed);
      }
    }

    final uri = Uri.parse(
      '$_endpoint?client=gtx&sl=$source&tl=$target&dt=t&q=${Uri.encodeComponent(text)}',
    );

    final response = await http.get(
      uri,
      headers: {
        HttpHeaders.userAgentHeader: 'tourist-safety-hub/1.0',
      },
    );

    _lastInvocation = DateTime.now();

    if (response.statusCode != 200) {
      throw Exception(
        'Translation failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is List && data.isNotEmpty && data[0] is List) {
      final buffer = StringBuffer();
      for (final segment in data[0]) {
        if (segment is List && segment.isNotEmpty) {
          buffer.write(segment[0]);
        }
      }
      final translated = buffer.toString().trim();
      return translated.isEmpty ? text : translated;
    }

    throw Exception('Unexpected translation response: ${response.body}');
  }
}


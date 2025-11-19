import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import 'gemini_service.dart';

class ActiveAlertService {
  static Future<List<Map<String, String>>> generateAlerts({
    required Position position,
    required List<Map<String, dynamic>> incidents,
    Map<String, dynamic>? weatherData,
  }) async {
    final prompt = _buildPrompt(
      position: position,
      incidents: incidents,
      weatherData: weatherData,
    );

    try {
      final response = await GeminiService.generateSafetyInsights(prompt);
      final parsed = _parseJson(response);
      final rawAlerts = (parsed['alerts'] as List?) ?? [];
      final normalized = rawAlerts.map<Map<String, String>>((alert) {
        final map = alert as Map<String, dynamic>;
        return {
          'title': (map['title'] ?? 'Zone Alert').toString(),
          'badge': (map['badge'] ?? 'Warning').toString(),
          'severity': (map['severity'] ?? 'caution').toString(),
          'message': (map['message'] ?? 'Stay alert near this zone.').toString(),
          'timeAgo': (map['timeAgo'] ?? 'Just now').toString(),
        };
      }).toList();

      if (normalized.isNotEmpty) {
        return normalized;
      }
    } catch (_) {
      // ignore and fallback
    }

    return _buildFallbackAlerts(incidents);
  }

  static String _buildPrompt({
    required Position position,
    required List<Map<String, dynamic>> incidents,
    Map<String, dynamic>? weatherData,
  }) {
    final payload = {
      'coordinates': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'recentIncidents': incidents.take(10).toList(),
      'weather': {
        'summary': weatherData?['summary'],
        'temperature': weatherData?['temperature'],
        'precipProbability': weatherData?['precipProbability'],
        'windSpeed': weatherData?['windSpeed'],
      },
    };

    return '''
You are an AI tourist safety dispatcher. Given the JSON context below, craft two concise alerts:
1. A "Zone Alert" focusing on geofenced or crowd-based risks.
2. A "Security Alert" focusing on criminal or safety threats.

Return STRICT JSON with this schema (no markdown, no prose):
{
  "alerts": [
    {
      "title": "Zone Alert",
      "badge": "Warning",
      "severity": "safe | caution | danger",
      "message": "short actionable summary",
      "timeAgo": "e.g. 2 min ago"
    },
    {
      "title": "Security Alert",
      "badge": "Danger",
      "severity": "safe | caution | danger",
      "message": "short actionable summary",
      "timeAgo": "e.g. 5 min ago"
    }
  ]
}

Guidelines:
- Reference locations, categories, or weather signals present in the context.
- Always keep messages under 140 characters.
- Prefer severity "danger" if high-risk incidents exist, otherwise "caution".

Context JSON:
${jsonEncode(payload)}
''';
  }

  static List<Map<String, String>> _buildFallbackAlerts(
    List<Map<String, dynamic>> incidents,
  ) {
    final highRisk = incidents.where(
      (incident) => (incident['riskLevel'] ?? '').toString().toLowerCase() == 'high',
    );

    final firstHigh = highRisk.isNotEmpty ? highRisk.first : null;
    final latest = incidents.isNotEmpty ? incidents.first : null;

    return [
      {
        'title': 'Zone Alert',
        'badge': 'Warning',
        'severity': highRisk.isNotEmpty ? 'danger' : 'caution',
        'message': firstHigh != null
            ? 'Increased risk near ${firstHigh['title'] ?? 'nearby zone'}. Stay vigilant.'
            : 'Crowd levels elevated nearby. Stick to well-lit areas.',
        'timeAgo': 'moments ago',
      },
      {
        'title': 'Security Alert',
        'badge': 'Danger',
        'severity': highRisk.isNotEmpty ? 'danger' : 'caution',
        'message': latest != null
            ? 'Recent ${latest['category'] ?? 'incident'} reported. Avoid secluded spots.'
            : 'No recent incident data. Keep emergency contacts handy.',
        'timeAgo': 'moments ago',
      },
    ];
  }

  static Map<String, dynamic> _parseJson(String response) {
    final trimmed = response.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    }

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (match != null) {
      return jsonDecode(match.group(0)!) as Map<String, dynamic>;
    }
    throw const FormatException('Unable to parse Gemini alerts response');
  }
}


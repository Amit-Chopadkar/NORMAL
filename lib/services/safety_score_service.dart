import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import 'gemini_service.dart';

class SafetyScoreService {
  static const double _defaultRadiusKm = 3;

  static Future<Map<String, dynamic>> getLiveSafetyScore({
    required Position position,
    double radiusKm = _defaultRadiusKm,
    List<Map<String, dynamic>>? incidents,
    String? address,
  }) async {
    final contextPayload = {
      'timestamp': DateTime.now().toIso8601String(),
      'coordinates': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'addressLabel': address ?? 'Unknown location',
      'searchRadiusKm': radiusKm,
      'incidentSummary': _buildIncidentSummary(incidents ?? []),
      'recentIncidents': (incidents ?? [])
          .take(8)
          .map(
            (incident) => {
              'title': incident['title'],
              'category': incident['category'],
              'riskLevel': incident['riskLevel'],
              'description': incident['description'],
              'reportedAt': incident['reportedAt'],
            },
          )
          .toList(),
    };

    final prompt = '''
You are an AI-powered tourist safety analyst. Review the JSON context below and estimate a live safety score for the area.

Respond with STRICT JSON matching this schema (no markdown, no commentary):
{
  "score": 0-100,
  "zoneStatus": "SAFE" | "CAUTION" | "DANGER",
  "crowdDensity": "LOW" | "MEDIUM" | "HIGH",
  "weather": "Clear" | "Rainy" | "Foggy" | "Windy" | "Unknown",
  "time": "HH:mm",
  "summary": "One sentence summary",
  "riskFactors": ["..."],
  "recommendations": ["..."]
}

Guidelines:
- If incidentSummary.highRiskCount is large, prefer "DANGER".
- Mention dominant risks (e.g., theft, assault, crowding) inside riskFactors.
- Provide actionable but concise recommendations.
- If weather is missing, infer from context (default to "Unknown").

Context JSON:
${jsonEncode(contextPayload)}
''';

    try {
      final response = await GeminiService.generateSafetyInsights(prompt);
      final parsed = _tryParseJson(response);
      parsed['fromAi'] = true;
      return parsed;
    } catch (_) {
      return _buildFallbackScore(
        address: address ?? 'Unknown',
        summary: _buildIncidentSummary(incidents ?? []),
      );
    }
  }

  static Map<String, dynamic> _buildIncidentSummary(
    List<Map<String, dynamic>> incidents,
  ) {
    int highRisk = 0;
    int mediumRisk = 0;
    int lowRisk = 0;

    for (final incident in incidents) {
      final level = (incident['riskLevel'] ?? '').toString().toLowerCase();
      if (level == 'high') {
        highRisk++;
      } else if (level == 'medium') {
        mediumRisk++;
      } else {
        lowRisk++;
      }
    }

    return {
      'totalIncidents': incidents.length,
      'highRiskCount': highRisk,
      'mediumRiskCount': mediumRisk,
      'lowRiskCount': lowRisk,
    };
  }

  static Map<String, dynamic> _tryParseJson(String response) {
    final trimmed = response.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    }

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (match != null) {
      return jsonDecode(match.group(0)!) as Map<String, dynamic>;
    }

    throw const FormatException('Unable to parse Gemini response');
  }

  static Map<String, dynamic> _buildFallbackScore({
    required String address,
    required Map<String, dynamic> summary,
  }) {
    final total = (summary['totalIncidents'] as int?) ?? 0;
    final high = (summary['highRiskCount'] as int?) ?? 0;
    final medium = (summary['mediumRiskCount'] as int?) ?? 0;

    int score = 90;
    score -= high * 8;
    score -= medium * 5;
    score -= total.clamp(0, 5) * 2;
    score = score.clamp(20, 95);

    final zoneStatus = score >= 75
        ? 'SAFE'
        : score >= 55
            ? 'CAUTION'
            : 'DANGER';

    final crowdDensity = total >= 6
        ? 'HIGH'
        : total >= 3
            ? 'MEDIUM'
            : 'LOW';

    final riskFactors = <String>[];
    if (high > 0) {
      riskFactors.add('Multiple high-risk incidents nearby');
    }
    if (medium > 0) {
      riskFactors.add('Several medium-risk reports in the vicinity');
    }
    if (total == 0) {
      riskFactors.add('No recent incidents logged');
    }

    final recommendations = <String>[
      if (zoneStatus != 'SAFE') 'Avoid secluded areas and stay alert',
      'Share your live location with trusted contacts',
      'Use in-app SOS if you feel unsafe',
    ];

    return {
      'score': score,
      'zoneStatus': zoneStatus,
      'crowdDensity': crowdDensity,
      'weather': 'Unknown',
      'time': DateTime.now().toString().substring(11, 16),
      'summary': 'Based on cached incident trends near $address.',
      'riskFactors': riskFactors.isEmpty
          ? ['Insufficient live data, using cached trends']
          : riskFactors,
      'recommendations': recommendations,
      'fromAi': false,
    };
  }
}


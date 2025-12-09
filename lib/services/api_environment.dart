import 'package:flutter/foundation.dart';

/// Central place to resolve API base URLs depending on platform and
/// build-time overrides. This keeps emulator/device specific hosts out
/// of the feature code and makes it easy to inject a different backend
/// via `--dart-define=PLACES_API_BASE_URL=...`.
class ApiEnvironment {
  static const String _placesOverride =
      String.fromEnvironment('PLACES_API_BASE_URL', defaultValue: '');
  static const String _googlePlacesOverride =
      String.fromEnvironment('GOOGLE_PLACES_API_KEY', defaultValue: '');
      static const String _bundledFallbackGoogleKey =
        'AIzaSyDtbyiNsjhAWH-7NJPT0xu_FJKRIi9YPzU';

  /// Resolve the backend base URL for the nearby places API.
  static String get placesBaseUrl {
    if (_placesOverride.isNotEmpty) {
      return _placesOverride;
    }

    if (kIsWeb) {
      return 'http://172.17.5.58:3000/api/places';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulators reach the host machine via 10.0.2.2 by default.
        return 'http://172.17.5.58:3000/api/places';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://172.17.5.58:3000/api/places';
    }
  }

  /// Google Places key for direct fallback calls (can be overridden via
  /// `--dart-define=GOOGLE_PLACES_API_KEY=...`).
  static String get googlePlacesApiKey {
    if (_googlePlacesOverride.isNotEmpty) {
      return _googlePlacesOverride;
    }
    return _bundledFallbackGoogleKey;
  }
}


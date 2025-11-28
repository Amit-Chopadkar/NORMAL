import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/zone.dart';
import '../models/zone_alert.dart';
import 'api_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

class ZoneService {
  static final List<Zone> _zones = [];
  static final List<ZoneAlert> _activeAlerts = [];
  static final Map<String, DateTime> _lastAlerted = {};
  static StreamSubscription<Position>? _locationSubscription;
  static final List<Function(ZoneAlert)> _alertListeners = [];
  static Timer? _zoneFetchTimer;

  // Hardcoded fallback zones (matching your geofence service)
  static final List<Zone> _fallbackZones = [
    Zone(
      id: '1',
      name: 'Remote Forest',
      type: 'danger',
      riskLevel: 'high',
      latitude: 20.0112,
      longitude: 73.7909,
      radius: 2000,
      color: '#ef4444',
    ),
    Zone(
      id: '2',
      name: 'Market Area',
      type: 'caution',
      riskLevel: 'medium',
      latitude: 20.0150,
      longitude: 73.7950,
      radius: 800,
      color: '#eab308',
    ),
    Zone(
      id: '3',
      name: 'Industrial Zone',
      type: 'danger',
      riskLevel: 'high',
      latitude: 20.0050,
      longitude: 73.7850,
      radius: 1500,
      color: '#ef4444',
    ),
    Zone(
      id: '4',
      name: 'Tourist Zone',
      type: 'safe',
      riskLevel: 'low',
      latitude: 20.0098,
      longitude: 73.7954,
      radius: 500,
      color: '#22c55e',
    ),
  ];

  // Start monitoring zones
  static Future<void> startMonitoring() async {
    // Load zones from backend and fallback
    await _loadZones();

    // Fetch zones periodically (every 5 minutes)
    _zoneFetchTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _loadZones(),
    );

    // Listen to location changes
    _locationSubscription = LocationService.getLocationStream().listen(
      (position) => _checkZones(position),
      onError: (error) => debugPrint('Location stream error: $error'),
    );

    debugPrint('Zone monitoring started');
  }

  // Stop monitoring
  static Future<void> stopMonitoring() async {
    _locationSubscription?.cancel();
    _zoneFetchTimer?.cancel();
    _locationSubscription = null;
    _zoneFetchTimer = null;
    debugPrint('Zone monitoring stopped');
  }

  // Load zones from API and fallback
  static Future<void> _loadZones() async {
    try {
      final position = LocationService.getLastKnownLocation();
      if (position != null) {
        final apiZones = await ApiService.getNearbyZones(
          position.latitude,
          position.longitude,
        );
        
        if (apiZones.isNotEmpty) {
          _zones.clear();
          _zones.addAll(apiZones);
          debugPrint('Loaded ${apiZones.length} zones from API');
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading zones from API: $e');
    }

    // Use fallback zones if API fails
    if (_zones.isEmpty) {
      _zones.clear();
      _zones.addAll(_fallbackZones);
      debugPrint('Using ${_fallbackZones.length} fallback zones');
    }
  }

  // Check current position against all zones
  static Future<void> _checkZones(Position position) async {
    for (final zone in _zones) {
      final distance = LocationService.calculateDistance(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      // Check if inside zone
      if (distance <= zone.radius) {
        await _handleZoneEntry(zone, distance);
      }
      // Check if approaching zone (within 500m buffer)
      else if (distance <= zone.radius + 500) {
        await _handleZoneApproach(zone, distance);
      }
      // Check if exited zone
      else {
        await _handleZoneExit(zone);
      }
    }
  }

  // Handle zone entry
  static Future<void> _handleZoneEntry(Zone zone, double distance) async {
    // Check if we already alerted for this zone recently
    if (_shouldAlert(zone.id, 'entering')) {
      final alert = ZoneAlert(
        zone: zone,
        eventType: 'entering',
        distance: distance,
        timestamp: DateTime.now(),
      );

      // Vibrate based on risk level
      await NotificationService.vibrate(alert.vibrationPattern);

      // Add to active alerts
      _activeAlerts.add(alert);

      // Notify listeners
      _notifyListeners(alert);

      // Save alert time
      _lastAlerted[zone.id] = DateTime.now();

      debugPrint('ZONE ALERT: Entering ${zone.name} (${zone.riskLevel})');
    }
  }

  // Handle approaching zone
  static Future<void> _handleZoneApproach(Zone zone, double distance) async {
    if (_shouldAlert(zone.id, 'approaching')) {
      final alert = ZoneAlert(
        zone: zone,
        eventType: 'approaching',
        distance: distance,
        timestamp: DateTime.now(),
      );

      // Single light vibration for approach warning
      await NotificationService.vibrate(1);

      // Notify listeners
      _notifyListeners(alert);

      // Save alert time
      _lastAlerted['${zone.id}_approaching'] = DateTime.now();

      debugPrint('ZONE ALERT: Approaching ${zone.name} - ${distance.toInt()}m away');
    }
  }

  // Handle zone exit
  static Future<void> _handleZoneExit(Zone zone) async {
    // Remove from active alerts
    _activeAlerts.removeWhere((alert) => alert.zone.id == zone.id);

    // Clear alert time
    _lastAlerted.remove(zone.id);
    _lastAlerted.remove('${zone.id}_approaching');
  }

  // Check if should alert (avoid duplicates)
  static bool _shouldAlert(String zoneId, String eventType) {
    final key = eventType == 'approaching' ? '${zoneId}_approaching' : zoneId;
    final lastAlert = _lastAlerted[key];

    if (lastAlert == null) return true;

    // Don't re-alert within 15 minutes for same zone
    final timeSinceLastAlert = DateTime.now().difference(lastAlert);
    return timeSinceLastAlert.inMinutes >= 15;
  }

  // Add alert listener
  static void addAlertListener(Function(ZoneAlert) listener) {
    _alertListeners.add(listener);
  }

  // Remove alert listener
  static void removeAlertListener(Function(ZoneAlert) listener) {
    _alertListeners.remove(listener);
  }

  // Notify all listeners
  static void _notifyListeners(ZoneAlert alert) {
    for (var listener in _alertListeners) {
      listener(alert);
    }
  }

  // Get current zone (highest risk zone user is in)
  static Zone? getCurrentZone() {
    if (_activeAlerts.isEmpty) return null;

    // Sort by risk level: high > medium > low
    final sorted = List<ZoneAlert>.from(_activeAlerts)
      ..sort((a, b) {
        final riskOrder = {'high': 3, 'medium': 2, 'low': 1};
        final aRisk = riskOrder[a.zone.riskLevel] ?? 0;
        final bRisk = riskOrder[b.zone.riskLevel] ?? 0;
        return bRisk.compareTo(aRisk);
      });

    return sorted.first.zone;
  }

  // Get all active alerts
  static List<ZoneAlert> getActiveAlerts() {
    return List.from(_activeAlerts);
  }

  // Get all zones
  static List<Zone> getAllZones() {
    return List.from(_zones);
  }

  // Manual refresh
  static Future<void> refreshZones() async {
    await _loadZones();
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      await _checkZones(position);
    }
  }

  // Cleanup
  static void dispose() {
    stopMonitoring();
    _zones.clear();
    _activeAlerts.clear();
    _lastAlerted.clear();
    _alertListeners.clear();
  }
}

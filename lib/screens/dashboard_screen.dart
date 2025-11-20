import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'geofence_events_screen.dart';

import '../services/active_alert_service.dart';
import '../services/incident_service.dart';
import '../services/location_service.dart';
import '../services/safety_score_service.dart';
import '../services/localization_service.dart';
import '../utils/constants.dart';
import '../utils/geofence_helper.dart';
import '../services/weather_service.dart';
import '../widgets/chatbot_widget.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const MethodChannel _notifyChannel = MethodChannel('tourapp/notifications');
  static const double _safetyRadiusKm = 3;
  StreamSubscription<Position>? _positionSub;
  // Last known position used to filter small updates
  Position? _lastProcessedPosition;
  bool _notifiedZone = false;
  // Track per-zone inside/outside state to send enter/exit notifications
  final Map<String, bool> _zoneStates = {};
  bool chatbotOpen = false;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  List<Map<String, dynamic>> _localIncidents = [];
  Map<String, dynamic>? _safetyScoreData;
  bool _isSafetyLoading = false;
  bool _isFetchingSafety = false;
  Timer? _safetyRefreshTimer;
  DateTime? _lastSafetyUpdate;
  String? _currentAddress;
  Map<String, dynamic>? _weatherData;
  bool _isWeatherLoading = false;
  bool _isFetchingWeather = false;
  DateTime? _lastWeatherUpdate;
  Map<String, String>? _weatherAlert;
  DateTime? _lastWeatherAlertUpdate;
  List<Map<String, String>> _activeAlerts = [];
  bool _alertsLoading = false;
  bool _isFetchingAlerts = false;
  DateTime? _lastAlertUpdate;

  @override
  void initState() {
    super.initState();
    _initLocationAndData();
    _startGeofenceMonitor();
  }

  // Monitor location and trigger notification on geofence enter
  void _startGeofenceMonitor() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      // Increase distanceFilter to reduce update frequency and CPU work
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
    ).listen(_handleLivePosition);
  }

  void _handleLivePosition(Position pos) {
    if (!mounted) return;
    // Ignore very small movements to avoid excessive UI rebuilds and network calls
    if (_lastProcessedPosition != null) {
      final moved = Geolocator.distanceBetween(
        _lastProcessedPosition!.latitude,
        _lastProcessedPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (moved < 5) {
        return;
      }
    }
    _lastProcessedPosition = pos;
    setState(() {
      _currentPosition = pos;
    });
    _evaluateGeofenceStatus(pos);
    // Reduce refresh frequency to avoid network bursts and main-thread work
    final shouldRefresh = _lastSafetyUpdate == null ||
        DateTime.now().difference(_lastSafetyUpdate!) >= const Duration(seconds: 60);
    if (shouldRefresh) {
      _refreshSafetyScore();
    }
    final shouldRefreshWeather = _lastWeatherUpdate == null ||
        DateTime.now().difference(_lastWeatherUpdate!) >= const Duration(minutes: 5);
    if (shouldRefreshWeather) {
      _refreshWeather();
    }
    final shouldRefreshAlerts = _lastAlertUpdate == null ||
        DateTime.now().difference(_lastAlertUpdate!) >= const Duration(minutes: 5);
    if (shouldRefreshAlerts) {
      _refreshActiveAlerts();
    }
  }

  Future<void> _evaluateGeofenceStatus(Position pos) async {
    for (final circle in _circles) {
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        circle.center.latitude,
        circle.center.longitude,
      );
      final id = circle.circleId.value;
      final isInside = dist <= circle.radius;

      final previous = _zoneStates[id] ?? false;
      // Transition: entered
      if (isInside && !previous) {
        _zoneStates[id] = true;
        final zoneName = _zoneNameForId(id) ?? id;
        // Persist event to Hive
        _logGeofenceEvent(zoneId: id, zoneName: zoneName, event: 'enter', lat: pos.latitude, lng: pos.longitude);
        // Send user notification
        await NotificationService.showAlertNotification(title: 'Entered Zone', body: 'You entered $zoneName', type: 'geofence_enter');
        break;
      }

      // Transition: exited
      if (!isInside && previous) {
        _zoneStates[id] = false;
        final zoneName = _zoneNameForId(id) ?? id;
        _logGeofenceEvent(zoneId: id, zoneName: zoneName, event: 'exit', lat: pos.latitude, lng: pos.longitude);
        await NotificationService.showAlertNotification(title: 'Exited Zone', body: 'You exited $zoneName', type: 'geofence_exit');
        break;
      }
      // No transition: keep state as-is
      if (!_zoneStates.containsKey(id)) {
        _zoneStates[id] = isInside;
      }
    }
  }

  void _startSafetyRefreshTimer() {
    _safetyRefreshTimer?.cancel();
    _safetyRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshSafetyScore();
      _refreshWeather();
      _refreshActiveAlerts();
    });
  }

  Future<void> _refreshSafetyScore({bool force = false}) async {
    if (_currentPosition == null) return;
    if (_isFetchingSafety && !force) return;
    _isFetchingSafety = true;
    if (force || _safetyScoreData == null) {
      setState(() {
        _isSafetyLoading = true;
      });
    }
    try {
      // Debug: log that a refresh has started
      // Avoid importing foundation at top-level; using debugPrint to keep output concise
      debugPrint('[Dashboard] Refreshing safety score at position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      final address = await LocationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final incidents = await IncidentService.getNearbyIncidents(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _safetyRadiusKm,
      );
      debugPrint('[Dashboard] Nearby incidents count: ${incidents.length}');
      final data = await SafetyScoreService.getLiveSafetyScore(
        position: _currentPosition!,
        radiusKm: _safetyRadiusKm,
        incidents: incidents,
        address: address,
      );
      debugPrint('[Dashboard] Received safety score data: $data');
      if (!mounted) return;
      setState(() {
        _currentAddress = address;
        _safetyScoreData = data;
        _isSafetyLoading = false;
        _lastSafetyUpdate = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSafetyLoading = false;
      });
    } finally {
      _isFetchingSafety = false;
    }
  }

  Future<void> _refreshWeather({bool force = false}) async {
    if (_currentPosition == null) return;
    if (_isFetchingWeather && !force) return;
    _isFetchingWeather = true;
    if (force || _weatherData == null) {
      setState(() {
        _isWeatherLoading = true;
      });
    }
    try {
      // Try OpenWeatherMap first (uses provided API key). Fall back to existing PirateWeather fetch.
      Map<String, dynamic>? data;
      final odata = await WeatherService.fetchOpenWeatherCurrent(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      if (odata != null) {
        data = {
          'summary': (odata['description'] ?? '').toString(),
          'temperature': (odata['temp'] as double?) ?? 0.0,
          'apparentTemperature': (odata['temp'] as double?) ?? 0.0,
          'humidity': (odata['humidity'] as double?) ?? 0.0,
          'precipProbability': (odata['precipProbability'] as double?) ?? 0.0,
          'windSpeed': (odata['windSpeed'] as double?) ?? 0.0,
          'icon': odata['icon'],
          'timestamp': DateTime.now(),
        };
      } else {
        data = await WeatherService.fetchCurrentWeather(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      }
      if (!mounted) return;
      setState(() {
        _weatherData = data;
        _isWeatherLoading = false;
        _lastWeatherUpdate = DateTime.now();
        _updateWeatherAlert(data!);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isWeatherLoading = false;
      });
    } finally {
      _isFetchingWeather = false;
    }
  }

  void _updateWeatherAlert(Map<String, dynamic> weatherData) {
    final summary = (weatherData['summary'] as String?) ?? 'Weather update';
    final temp = (weatherData['temperature'] as double?) ?? 0;
    final precip = (weatherData['precipProbability'] as double?) ?? 0;
    final wind = (weatherData['windSpeed'] as double?) ?? 0;
    final severity = precip >= 0.6
        ? 'danger'
        : precip >= 0.3 || wind >= 40
            ? 'caution'
            : 'safe';
    final message =
        '${temp.toStringAsFixed(1)}°C · $summary · Rain ${(precip * 100).round()}%';
    _weatherAlert = {
      'title': 'Weather Update',
      'badge': 'Info',
      'severity': severity,
      'message': message,
    };
    _lastWeatherAlertUpdate = DateTime.now();
  }

  Future<void> _refreshActiveAlerts({bool force = false}) async {
    if (_currentPosition == null) return;
    if (_isFetchingAlerts && !force) return;
    if (_localIncidents.isEmpty && _activeAlerts.isNotEmpty && !force) return;
    _isFetchingAlerts = true;
    if (force || _activeAlerts.isEmpty) {
      setState(() {
        _alertsLoading = true;
      });
    }
    try {
      final alerts = await ActiveAlertService.generateAlerts(
        position: _currentPosition!,
        incidents: _localIncidents,
        weatherData: _weatherData,
      );
      if (!mounted) return;
      setState(() {
        _activeAlerts = alerts;
        _alertsLoading = false;
        _lastAlertUpdate = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alertsLoading = false;
      });
    } finally {
      _isFetchingAlerts = false;
    }
  }

  Future<void> _showSystemNotification(String title, String body) async {
    try {
      await _notifyChannel.invokeMethod('showNotification', {'title': title, 'body': body});
    } catch (_) {}
  }
  @override
  void dispose() {
    _positionSub?.cancel();
    _safetyRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocationAndData() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = pos;
      });
      await _refreshSafetyScore(force: true);
      await _refreshWeather(force: true);
      _startSafetyRefreshTimer();

      // Load incidents from local storage to show markers
      final incidents = await IncidentService.getAllIncidents();
      for (var inc in incidents) {
        if (inc['location'] != null) {
          final lat = (inc['location']['latitude'] as num).toDouble();
          final lng = (inc['location']['longitude'] as num).toDouble();
          _markers.add(Marker(
            markerId: MarkerId(inc['id'] ?? DateTime.now().toIso8601String()),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: inc['title'] ?? 'Incident', snippet: inc['category']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));
        }
      }
      setState(() {
        _localIncidents = incidents;
      });
      await _refreshActiveAlerts(force: true);

      // Predefined geofence circles
      // Use helper to build fixed circles from constants
      _circles.addAll(GeofenceHelper.buildFixedCircles());
      setState(() {});
      // Initialize per-zone state based on current position (no notifications)
      if (_currentPosition != null && _circles.isNotEmpty) {
        for (final circle in _circles) {
          final dist = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            circle.center.latitude,
            circle.center.longitude,
          );
          _zoneStates[circle.circleId.value] = dist <= circle.radius;
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return _buildDashboard(context);
      },
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final zoneStatus = _zoneStatusLabel();
    final timeLabel = _timeLabel();
    final crowdDensity = _crowdDensityLabel();
    final weatherLabel = _weatherLabel();
    final scoreValue = _formatScoreValue();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24), // Top padding
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.withValues(alpha: 0.2),
                            child: const Text('RK'),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rajesh Kumar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'ID: TID-2025-001234',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          // Open in-app geofence events viewer
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const GeofenceEventsScreen(),
                          ));
                        },
                        child: Stack(
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              size: 28,
                              color: Colors.grey,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Safety Score Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.grey[800]),
                          const SizedBox(width: 8),
                          Text(
                            tr('tourist_safety_score'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              scoreValue,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                            Text(
                              tr('out_of_100'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSafetyItem(tr('current_zone'), zoneStatus, _zoneStatusColor(zoneStatus)),
                      const SizedBox(height: 12),
                      _buildSafetyItem(tr('time'), timeLabel, Colors.grey),
                      const SizedBox(height: 12),
                      _buildSafetyItem(tr('crowd_density'), crowdDensity, _crowdDensityColor(crowdDensity)),
                      const SizedBox(height: 12),
                      _buildSafetyItem(tr('weather'), weatherLabel, Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Map Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            tr('your_location_nearby_zones'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Map
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: _currentPosition == null
                              ? const Center(child: CircularProgressIndicator())
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    zoom: 14,
                                  ),
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: false,
                                  mapToolbarEnabled: true,
                                  markers: _markers,
                                  circles: _circles,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Geofence button removed per request
                      const SizedBox(height: 12),
                      // Current Location
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.my_location, color: Colors.green[600]),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('current_location'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _currentAddress ?? 'Detecting address...',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nearby Zones',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildNearbyZone('Tourist Zone', '0.2 km', 'SAFE', Colors.green),
                      const SizedBox(height: 8),
                      _buildNearbyZone('Market Area', '0.5 km', 'CAUTION', Colors.orange),
                      const SizedBox(height: 8),
                      _buildNearbyZone('Remote forest', '2.1 km', 'Danger', Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Active Alerts
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.black87),
                              const SizedBox(width: 8),
                              Text(
                                tr('active_alerts'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (_activeAlerts.length + (_weatherAlert != null ? 1 : 0)).toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_alertsLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_activeAlerts.isEmpty && _weatherAlert == null)
                        Text(
                          tr('no_data'),
                          style: const TextStyle(color: Colors.grey),
                        )
                      else
                        Column(
                          children: [
                            ..._activeAlerts.map(
                              (alert) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildAlert(
                                  alert['title'] ?? 'Alert',
                                  alert['badge'] ?? 'Info',
                                  _alertColor(alert['severity'] ?? 'caution'),
                                  alert['message'] ?? 'Details unavailable.',
                                  alert['timeAgo'] ?? 'moments ago',
                                ),
                              ),
                            ),
                            if (_weatherAlert != null)
                              _buildAlert(
                                _weatherAlert!['title'] ?? 'Weather Update',
                                _weatherAlert!['badge'] ?? 'Info',
                                _alertColor(_weatherAlert!['severity'] ?? 'caution'),
                                _weatherAlert!['message'] ?? 'Latest weather data unavailable.',
                                _weatherAlert!['timeAgo'] ??
                                    _formatTimeAgo(_lastWeatherAlertUpdate),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Chatbot Button
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.blue[800],
              onPressed: () {
                setState(() {
                  chatbotOpen = !chatbotOpen;
                });
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.smart_toy_outlined, color: Colors.white),
                  Positioned(
                    top: -18,
                    right: -18,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Chatbot Widget
          if (chatbotOpen)
            ChatbotWidget(
              onClose: () {
                setState(() {
                  chatbotOpen = false;
                });
              },
            ),
        ],
      ),
      // Bottom navigation is managed by `MainNavigationScreen` in `main.dart`.
    );
  }

  String _formatScoreValue() {
    final value = _safetyScoreData?['score'];
    if (value is num) {
      final clamped = value.clamp(0, 100);
      return clamped.round().toString();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return _isSafetyLoading ? '—' : '--';
  }

  String _zoneStatusLabel() {
    final value = _safetyScoreData?['zoneStatus'];
    if (value is String && value.trim().isNotEmpty) {
      return value.toUpperCase();
    }
    return _isSafetyLoading ? 'Updating...' : 'Unknown';
  }

  String _timeLabel() {
    final value = _safetyScoreData?['time'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    if (_lastSafetyUpdate != null) {
      return _formatTime(_lastSafetyUpdate!);
    }
    return _isSafetyLoading ? 'Updating...' : '--:--';
  }

  String _crowdDensityLabel() {
    final value = _safetyScoreData?['crowdDensity'];
    if (value is String && value.trim().isNotEmpty) {
      return value.toUpperCase();
    }
    return _isSafetyLoading ? 'Calculating...' : 'Unknown';
  }

  String _weatherLabel() {
    if (_weatherData != null) {
      final temp = (_weatherData?['temperature'] as double?) ?? 0;
      final summary = (_weatherData?['summary'] as String?) ?? 'Unknown';
      final tempLabel = temp == 0 ? '--' : temp.toStringAsFixed(1);
      return '$tempLabel°C · $summary';
    }
    final value = _safetyScoreData?['weather'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return _isWeatherLoading ? 'Detecting...' : 'Unknown';
  }

  Color _zoneStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SAFE':
        return Colors.green;
      case 'CAUTION':
        return Colors.orange;
      case 'DANGER':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _crowdDensityColor(String density) {
    switch (density.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _alertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'danger':
        return Colors.red;
      case 'caution':
        return Colors.orange;
      case 'safe':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatTime(DateTime time) {
    final hours = _twoDigit(time.hour);
    final minutes = _twoDigit(time.minute);
    return '$hours:$minutes';
  }

  String _twoDigit(int value) => value.toString().padLeft(2, '0');

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'moments ago';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }

  String? _zoneNameForId(String id) {
    try {
      final zones = AppConstants.geofenceZones;
      for (final z in zones) {
        if ((z['id'] as String) == id) return (z['name'] as String?) ?? id;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _logGeofenceEvent({required String zoneId, required String zoneName, required String event, required double lat, required double lng}) async {
    try {
      const boxName = 'geofence_events';
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      final box = Hive.box(boxName);
      final id = 'GE-${DateTime.now().millisecondsSinceEpoch}';
      final payload = {
        'id': id,
        'zoneId': zoneId,
        'zoneName': zoneName,
        'event': event,
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await box.put(id, payload);
      debugPrint('[Geofence] Logged event: $payload');
    } catch (e) {
      debugPrint('[Geofence] Failed to log event: $e');
    }
  }

  Widget _buildSafetyItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 8),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyZone(String name, String distance, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  distance,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(String title, String badge, Color badgeColor, String message, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: badgeColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

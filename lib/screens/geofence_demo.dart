import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

/// A simple Geofence demo screen.
/// Note: This screen is not set as the app home by default.
class GeofenceDemo extends StatefulWidget {
  const GeofenceDemo({Key? key}) : super(key: key);

  @override
  State<GeofenceDemo> createState() => _GeofenceDemoState();
}

class _GeofenceDemoState extends State<GeofenceDemo> {
  final _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: true,
    allowMockLocations: false,
    printDevLog: true,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
  );

  final List<String> _events = <String>[];

  final List<Geofence> _geofenceList = <Geofence>[
    Geofence(
      id: 'place_1',
      latitude: 20.1106505,
      longitude: 73.7242486,
      radius: [
        GeofenceRadius(id: 'r_100', length: 100),
        GeofenceRadius(id: 'r_25', length: 25),
      ],
      data: {'label': 'Place 1'},
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Notifications disabled: _initNotifications() removed
      final ok = await _requestPermissions();
      if (!ok) {
        _addEvent('Permissions not granted');
        return;
      }

      _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
      _geofenceService.addActivityChangeListener(_onActivityChanged);
      _geofenceService.addLocationChangeListener(_onLocationChanged);
      _geofenceService.addLocationServicesStatusChangeListener(_onLocationServicesStatusChanged);
      _geofenceService.addStreamErrorListener(_onError);

      try {
        await _geofenceService.start(_geofenceList);
        _addEvent('Geofence service started');
      } catch (e) {
        _addEvent('Start error: $e');
      }
    });
  }

  Future<bool> _requestPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    final activity = await Permission.activityRecognition.request();
    // Request notification permission on Android 13+/iOS
    try {
      await Permission.notification.request();
    } catch (_) {}
    // If you need background location, request Permission.locationAlways here.
    return status.isGranted && activity.isGranted;
  }
  // Notification code removed: flutter_local_notifications dependency removed due to build error

  void _addEvent(String s) {
    setState(() => _events.insert(0, '${DateTime.now().toIso8601String()} - $s'));
  }

  Future<void> _onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    final label = (geofence.data != null && geofence.data!['label'] != null) ? geofence.data!['label'] : geofence.id;
    final msg = 'Geofence ${geofence.id} ${geofenceStatus.toString()} radius:${geofenceRadius.length} at ${location.latitude},${location.longitude}';
    _addEvent(msg);
    // Notification on geofence enter disabled
  }

  void _onActivityChanged(Activity prev, Activity curr) {
    _addEvent('Activity: ${curr.type} (${curr.confidence})');
  }

  void _onLocationChanged(Location location) {
    _addEvent('Location: ${location.latitude},${location.longitude}');
  }

  void _onLocationServicesStatusChanged(bool status) {
    _addEvent('Location services enabled: $status');
  }

  void _onError(dynamic error) {
    _addEvent('Error: ${error.toString()}');
  }

  @override
  void dispose() {
    try {
      _geofenceService.clearAllListeners();
      _geofenceService.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geofence Demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _geofenceService.pause();
                    _addEvent('Service paused');
                  },
                  child: const Text('Pause'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _geofenceService.resume();
                    _addEvent('Service resumed');
                  },
                  child: const Text('Resume'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _geofenceService.stop();
                    _addEvent('Service stopped');
                  },
                  child: const Text('Stop'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, i) => ListTile(title: Text(_events[i])),
            ),
          ),
        ],
      ),
    );
  }
}


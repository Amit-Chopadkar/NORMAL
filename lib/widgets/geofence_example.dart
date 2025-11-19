import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Minimal copyable example based on the plugin README.
/// Use this widget to start/stop the geofence service and observe events.
class GeofenceExample extends StatefulWidget {
  const GeofenceExample({Key? key}) : super(key: key);

  @override
  _GeofenceExampleState createState() => _GeofenceExampleState();
}

class _GeofenceExampleState extends State<GeofenceExample> {
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

  final List<Geofence> _geofenceList = <Geofence>[
    Geofence(
      id: 'place_1',
      latitude: 20.1106505,
      longitude: 73.7242486,
      radius: [
        GeofenceRadius(id: 'radius_100m', length: 100),
        GeofenceRadius(id: 'radius_25m', length: 25),
      ],
    ),
  ];

  final List<String> _events = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Permission.locationWhenInUse.request();
      await Permission.activityRecognition.request();

      _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
      _geofenceService.addLocationChangeListener(_onLocationChanged);
      _geofenceService.addLocationServicesStatusChangeListener(_onLocationServicesStatusChanged);
      _geofenceService.addActivityChangeListener(_onActivityChanged);
      _geofenceService.addStreamErrorListener(_onError);

      try {
        await _geofenceService.start(_geofenceList);
        _addEvent('Started geofence example');
      } catch (e) {
        _addEvent('Start error: $e');
      }
    });
  }

  void _addEvent(String s) {
    setState(() => _events.insert(0, '${DateTime.now().toIso8601String()} - $s'));
  }

  Future<void> _onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    _addEvent('Geofence ${geofence.id} ${geofenceStatus.toString()} radius:${geofenceRadius.length} at ${location.latitude},${location.longitude}');
  }

  void _onActivityChanged(Activity prev, Activity curr) => _addEvent('Activity: ${curr.type} (${curr.confidence})');

  void _onLocationChanged(Location location) => _addEvent('Location: ${location.latitude},${location.longitude}');

  void _onLocationServicesStatusChanged(bool status) => _addEvent('Location services: $status');

  void _onError(dynamic error) => _addEvent('Error: ${error.toString()}');

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
    return Card(
      child: Column(
        children: [
          const ListTile(title: Text('Geofence Example')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _geofenceService.start(_geofenceList);
                _addEvent('Manually started');
              } catch (e) {
                _addEvent('Manual start error: $e');
              }
            },
            child: const Text('Start Example'),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: _events.length,
              itemBuilder: (c, i) => ListTile(title: Text(_events[i], style: const TextStyle(fontSize: 12))),
            ),
          ),
        ],
      ),
    );
  }
}


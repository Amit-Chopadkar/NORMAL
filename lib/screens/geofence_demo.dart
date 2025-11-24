import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/constants.dart';

/// A simple Geofence demo screen.
/// Note: This screen is not set as the app home by default.
class GeofenceDemo extends StatefulWidget {
  const GeofenceDemo({Key? key}) : super(key: key);

  @override
  State<GeofenceDemo> createState() => _GeofenceDemoState();
}

class _GeofenceDemoState extends State<GeofenceDemo> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final _geofenceService = GeofenceService.instance.setup(
    interval: 1000, // 1 second for faster location updates
    accuracy: 10,
    loiteringDelayMs: 0, // No delay for geofence enter events
    statusChangeDelayMs: 0, // No delay for status change reporting
    useActivityRecognition: true,
    allowMockLocations: false,
    printDevLog: true,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
  );

  final List<String> _events = <String>[];

  final List<Geofence> _geofenceList = List<Geofence>.from(
    AppConstants.geofenceZones.map((zone) => Geofence(
      id: zone['id'],
      latitude: zone['latitude'],
      longitude: zone['longitude'],
      radius: [
        GeofenceRadius(id: 'r_${zone['radius']}', length: zone['radius'].toDouble()),
      ],
      data: {'label': zone['name']},
    ))
  );

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> _requestPermissions() async {
    // Request foreground location first
    final status = await Permission.locationWhenInUse.request();
    final activity = await Permission.activityRecognition.request();

    // On Android, background (always) location must be requested separately
    bool backgroundGranted = false;
    if (Platform.isAndroid) {
      // Only request `locationAlways` if we already have foreground permission
      if (status.isGranted) {
        final always = await Permission.locationAlways.request();
        backgroundGranted = always.isGranted;
        if (!backgroundGranted && always.isPermanentlyDenied) {
          // Suggest the user open app settings to enable background location
          // (Don't block; the geofence service can still run in foreground)
          await openAppSettings();
        }
      }
    }

    // Request notification permission on Android 13+/iOS (best-effort)
    try {
      await Permission.notification.request();
    } catch (_) {}

    // Return true if foreground location and activity recognition are granted.
    // For background geofencing to fully work when app is backgrounded, background
    // location (`locationAlways`) is also recommended on Android.
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

    // Debug print to verify event firing
    print('[DEBUG] Geofence event: $msg');

    // Show notification on geofence enter/exit
    String notifTitle = 'Geofence Alert';
    String notifBody = '';
    if (geofenceStatus == GeofenceStatus.ENTER) {
      notifBody = 'Entered $label';
    } else if (geofenceStatus == GeofenceStatus.EXIT) {
      notifBody = 'Exited $label';
    } else {
      notifBody = 'Status changed: ${geofenceStatus.toString()}';
    }
    await flutterLocalNotificationsPlugin.show(
      0,
      notifTitle,
      notifBody,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'geofence_channel',
          'Geofence Events',
          channelDescription: 'Notifications for geofence entry/exit',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
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


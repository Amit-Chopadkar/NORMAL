import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class GeofenceEventsScreen extends StatefulWidget {
  const GeofenceEventsScreen({super.key});

  @override
  State<GeofenceEventsScreen> createState() => _GeofenceEventsScreenState();
}

class _GeofenceEventsScreenState extends State<GeofenceEventsScreen> {
  static const String _boxName = 'geofence_events';
  Box? _box;
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
      _box = Hive.box(_boxName);
      final keys = _box!.keys.toList();
      final list = <Map<String, dynamic>>[];
      for (final k in keys) {
        final raw = _box!.get(k);
        if (raw is Map) list.add(Map<String, dynamic>.from(raw));
      }
      // Sort by timestamp desc
      list.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));
      setState(() {
        _events = list;
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _clearAll() async {
    if (_box == null) return;
    await _box!.clear();
    await _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Clear all events?'),
                  content: const Text('This will permanently delete all stored geofence events.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Clear')),
                  ],
                ),
              );
              if (ok == true) await _clearAll();
            },
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('No geofence events logged yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _events.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, idx) {
                    final e = _events[idx];
                    final ts = e['timestamp'] ?? '';
                    final zone = e['zoneName'] ?? e['zoneId'] ?? 'Unknown';
                    final event = e['event'] ?? 'event';
                    final lat = e['latitude']?.toString() ?? '-';
                    final lng = e['longitude']?.toString() ?? '-';
                    return ListTile(
                      title: Text('$zone — ${event.toString().toUpperCase()}'),
                      subtitle: Text('$ts\nLat: $lat, Lng: $lng'),
                      isThreeLine: true,
                    );
                  },
                ),
    );
  }
}

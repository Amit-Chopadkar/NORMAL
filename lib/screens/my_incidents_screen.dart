import 'package:flutter/material.dart';
import '../services/incident_service.dart';

class MyIncidentsScreen extends StatefulWidget {
  const MyIncidentsScreen({Key? key}) : super(key: key);

  @override
  State<MyIncidentsScreen> createState() => _MyIncidentsScreenState();
}

class _MyIncidentsScreenState extends State<MyIncidentsScreen> {
  late Future<List<Map<String, dynamic>>> _incidentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshIncidents();
  }

  void _refreshIncidents() {
    setState(() {
      _incidentsFuture = IncidentService.getAllIncidents();
    });
  }

  String _getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'ff5252';
      case 'medium':
        return 'ffc107';
      case 'low':
        return '4caf50';
      default:
        return '9e9e9e';
    }
  }

  Color _getRiskLevelColorWidget(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Incident Reports'),
        backgroundColor: Colors.red[700],
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshIncidents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _incidentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final incidents = snapshot.data ?? [];

          if (incidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No incidents reported yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    incident['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'ID: ${incident['id']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getRiskLevelColorWidget(
                          incident['riskLevel'] ?? 'low'),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.report_gmailerrorred,
                        color: Colors.white),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Category',
                            incident['category'] ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Status',
                            incident['status'] ?? 'N/A',
                            statusChip: true,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Risk Level',
                            incident['riskLevel'] ?? 'N/A',
                            riskChip: true,
                            riskLevel: incident['riskLevel'] ?? 'low',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Reported At',
                            _formatDateTime(incident['reportedAt']),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Location',
                            incident['location']['address'] ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            incident['description'] ?? 'N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (incident['emergencyResponse'] != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🚨 Emergency Response Requested',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Urgency: ${incident['emergencyResponse']['urgencyLevel']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Requested: ${_formatDateTime(incident['emergencyResponse']['requestedAt'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool statusChip = false,
    bool riskChip = false,
    String riskLevel = 'low',
  }) {
    if (statusChip) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Chip(
            label: Text(value),
            backgroundColor: _getStatusColor(value),
            labelStyle: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    if (riskChip) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Chip(
            label: Text(value),
            backgroundColor: _getRiskLevelColorWidget(riskLevel),
            labelStyle: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return Colors.blue;
      case 'in_progress':
      case 'investigating':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'emergency_response_requested':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}

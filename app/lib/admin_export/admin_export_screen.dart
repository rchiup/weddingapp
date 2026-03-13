import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'admin_export_csv.dart';
import 'admin_export_service.dart';

/// Pantalla de exportación admin
class AdminExportScreen extends StatefulWidget {
  const AdminExportScreen({super.key});

  @override
  State<AdminExportScreen> createState() => _AdminExportScreenState();
}

class _AdminExportScreenState extends State<AdminExportScreen> {
  final AdminExportService _service = AdminExportService();
  bool _isLoading = false;

  Future<void> _exportRsvps(String eventId) async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.fetchRsvps(eventId);
      final rows = data.map((item) {
        return [
          item['id']?.toString() ?? '',
          item['attending']?.toString() ?? '',
          item['plus_one']?.toString() ?? '',
          item['dietary_notes']?.toString() ?? '',
          item['updated_at']?.toString() ?? '',
        ];
      }).toList();
      final csv = _service.buildCsv(
        ['id', 'attending', 'plus_one', 'dietary_notes', 'updated_at'],
        rows,
      );
      await exportCsv('rsvps_$eventId.csv', csv);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportGuests(String eventId) async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.fetchGuests(eventId);
      final rows = data.map((item) {
        return [
          item['id']?.toString() ?? '',
          item['name']?.toString() ?? '',
          item['tableNumber']?.toString() ?? '',
          item['status']?.toString() ?? '',
        ];
      }).toList();
      final csv = _service.buildCsv(
        ['id', 'name', 'tableNumber', 'status'],
        rows,
      );
      await exportCsv('guests_$eventId.csv', csv);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = context.read<UserContextProvider>().eventId ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Exportar datos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _exportRsvps(eventId),
            child: const Text('Export RSVPs'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _exportGuests(eventId),
            child: const Text('Export Guests'),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

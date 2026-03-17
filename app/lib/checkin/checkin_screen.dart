import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../user_context/user_context_provider.dart';
import 'checkin_service.dart';

/// Pantalla "Ya llegué" - check-in al evento
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final CheckinService _service = CheckinService();
  bool _loading = false;
  bool _done = false;
  bool _loadingArrivals = false;
  String _query = '';
  List<Map<String, dynamic>> _arrivals = [];

  String _formatArrivalTime(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is String) dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    // Convertir a hora de Chile (America/Santiago)
    final loc = tz.getLocation('America/Santiago');
    final chile = tz.TZDateTime.from(dt, loc);
    return DateFormat('HH:mm').format(chile);
  }

  Future<void> _doCheckin() async {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId;
    final userId = userContext.userId;
    final name = userContext.userName ?? 'Invitado';

    if (eventId == null || eventId.isEmpty || userId == null || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes unirte a un evento primero')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.checkIn(eventId: eventId, userId: userId, name: name);
      if (mounted) {
        setState(() {
          _loading = false;
          _done = true;
        });
      }
      await _loadArrivals();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo registrar la llegada: $e')),
        );
      }
    }
  }

  Future<void> _loadArrivals() async {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId;
    if (eventId == null || eventId.isEmpty) return;
    setState(() => _loadingArrivals = true);
    try {
      final uri = Uri.parse('https://weddingapp-c6ix.onrender.com').replace(
        path: '/api/gallery/event/$eventId/arrivals',
        queryParameters: _query.trim().isEmpty ? null : {'q': _query.trim()},
      );
      // usar Dio de CheckinService? mantenemos simple con Firestore? -> API con http
      // Para evitar dependencias extra, usamos NetworkImage fetch indirecto? no. Usamos Dio via service:
      final dio = Dio();
      final res = await dio.get(uri.toString());
      final data = res.data as Map<String, dynamic>? ?? {};
      final items = (data['items'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      if (mounted) {
        setState(() {
          _arrivals = items;
        });
      }
    } catch (_) {
      // silencioso: no queremos romper la pantalla si el backend falla
    } finally {
      if (mounted) setState(() => _loadingArrivals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_done) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              '¡Listo! Ya registraste tu llegada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar quién llegó...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                _query = v;
                _loadArrivals();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Llegaron: ${_arrivals.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _loadingArrivals ? null : _loadArrivals,
                  icon: _loadingArrivals
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingArrivals
                  ? const Center(child: CircularProgressIndicator())
                  : _arrivals.isEmpty
                      ? const Center(
                          child: Text(
                            'Aún no hay llegadas registradas.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _arrivals.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final a = _arrivals[i];
                            final name = (a['name'] ?? 'Invitado').toString();
                            final time = _formatArrivalTime(a['arrivalAt']);
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.verified, color: Colors.green),
                              title: Text(name),
                              subtitle: time.isEmpty ? null : Text('Llegó a las $time'),
                            );
                          },
                        ),
            ),
          ] else ...[
            const Text(
              '¿Ya llegaste al evento?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Marca tu llegada para ver quién más ya llegó.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _doCheckin,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.celebration),
              label: Text(_loading ? 'Registrando...' : 'Ya llegué'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/entry'),
            child: const Text('Volver al menú'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../lista_novios/novios_registry_service.dart';
import '../user_context/user_context_provider.dart';
import '../utils/nav_safe.dart';
import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../ui/custom_card.dart';
import 'checkin_service.dart';

/// Pantalla "Ya llegué" - check-in al evento
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final CheckinService _service = CheckinService();
  final NoviosRegistryService _registryService = NoviosRegistryService();
  static const double _autoCheckinRadiusMeters = 250;
  bool _loading = false;
  bool _done = false;
  bool _loadingArrivals = false;
  bool _loadingGeo = false;
  String _query = '';
  String? _geoStatus;
  List<Map<String, dynamic>> _arrivals = [];
  Map<String, dynamic>? _eventLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadEventLocation();
      await _syncAlreadyArrived();
    });
  }

  Future<void> _syncAlreadyArrived() async {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId ?? '';
    final userId = userContext.userId ?? '';
    if (eventId.isEmpty || userId.isEmpty) return;
    final arrived = await _service.hasArrived(eventId: eventId, userId: userId);
    if (!mounted) return;
    if (arrived) {
      setState(() => _done = true);
      await _loadArrivals();
    }
  }

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

  Future<void> _loadEventLocation() async {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId;
    if (eventId == null || eventId.isEmpty) return;
    try {
      final location = await _registryService.getLocation(eventId);
      if (!mounted) return;
      setState(() {
        _eventLocation = location;
      });
    } catch (_) {
      // Si no hay ubicación configurada, simplemente no mostramos el flujo automático.
    }
  }

  Future<void> _enableLocationCheck() async {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId;
    if (eventId == null || eventId.isEmpty) {
      if (!mounted) return;
      setState(() => _geoStatus = 'Debes unirte a un evento primero.');
      return;
    }

    if (_eventLocation == null) {
      await _loadEventLocation();
    }

    final location = _eventLocation;
    final latitude = location?['latitude'];
    final longitude = location?['longitude'];
    if (latitude is! num || longitude is! num) {
      if (!mounted) return;
      setState(() => _geoStatus = 'Los novios aún no configuraron la ubicación del evento.');
      return;
    }

    setState(() {
      _loadingGeo = true;
      _geoStatus = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _geoStatus = 'Activa la ubicación del celular para usar el check-in automático.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _geoStatus = 'Sin permiso de ubicación, no puedo marcarte automáticamente.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _geoStatus = 'La ubicación quedó bloqueada. Actívala desde el navegador o ajustes.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude.toDouble(),
        longitude.toDouble(),
      );

      if (!mounted) return;
      if (distance <= _autoCheckinRadiusMeters) {
        setState(() => _geoStatus = 'Estás dentro del rango. Marcando llegada...');
        await _doCheckin();
      } else {
        setState(
          () => _geoStatus =
              'Te falta aprox. ${distance.toStringAsFixed(0)} m para marcar automático. Igual puedes hacerlo manual.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _geoStatus = 'No se pudo usar la ubicación: $e');
    } finally {
      if (mounted) setState(() => _loadingGeo = false);
    }
  }

  Future<void> _loadArrivals() async {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId;
    if (eventId == null || eventId.isEmpty) return;
    setState(() => _loadingArrivals = true);
    try {
      final items = await _service.getArrivals(eventId: eventId, query: _query);
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
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_done) ...[
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check-in automático', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'Activa la ubicación para que te marque solo si ya llegaste al evento.',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  CustomButton(
                    label: _loadingGeo ? 'Verificando...' : 'Activar ubicación',
                    icon: Icons.my_location,
                    loading: _loadingGeo,
                    onPressed: _loadingGeo ? null : _enableLocationCheck,
                  ),
                  if (_geoStatus != null) ...[
                    const SizedBox(height: AppSpacing.x1),
                    Text(_geoStatus!, style: AppTextStyles.subtitle),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
          ],
          if (_done) ...[
            CustomCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  const SizedBox(width: AppSpacing.x1_5),
                  Expanded(
                    child: Text(
                      '¡Listo! Ya registraste tu llegada.',
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar quién llegó...',
              ),
              onChanged: (v) {
                _query = v;
                _loadArrivals();
              },
            ),
            const SizedBox(height: AppSpacing.x1_5),
            Row(
              children: [
                Text(
                  'Llegaron: ${_arrivals.length}',
                  style: AppTextStyles.title.copyWith(fontSize: 14),
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
            const SizedBox(height: AppSpacing.x1),
            Expanded(
              child: _loadingArrivals
                  ? const Center(child: CircularProgressIndicator())
                  : _arrivals.isEmpty
                      ? Center(child: Text('Aún no hay llegadas registradas.', style: AppTextStyles.subtitle))
                      : ListView.separated(
                          itemCount: _arrivals.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final a = _arrivals[i];
                            final name = (a['name'] ?? 'Invitado').toString();
                            final time = _formatArrivalTime(a['arrivalAt']);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.x1),
                              child: CustomCard(
                                padding: const EdgeInsets.all(AppSpacing.x1_5),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.verified, color: Colors.green),
                                    ),
                                    const SizedBox(width: AppSpacing.x1_5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: AppTextStyles.title.copyWith(fontSize: 14)),
                                          if (time.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text('Llegó a las $time', style: AppTextStyles.subtitle),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ] else ...[
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Ya llegaste al evento?', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'Si prefieres no usar ubicación, marca tu llegada manualmente para ver quién más llegó.',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  CustomButton(
                    label: _loading ? 'Registrando...' : 'Ya llegué',
                    icon: Icons.celebration_outlined,
                    loading: _loading,
                    onPressed: _loading ? null : _doCheckin,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x2),
          Center(
            child: TextButton(
              onPressed: () => popOrEntry(context),
              child: const Text('Volver al menú'),
            ),
          ),
        ],
      ),
    );
  }
}

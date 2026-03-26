import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../event_join/event_join_service.dart';
import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../ui/custom_card.dart';
import '../user_context/user_context_provider.dart';
import '../utils/nav_safe.dart';
import '../utils/nested_flow_navigator.dart';
import 'novios_registry_service.dart';

class NoviosAdminScreen extends StatefulWidget {
  const NoviosAdminScreen({super.key});

  @override
  State<NoviosAdminScreen> createState() => _NoviosAdminScreenState();
}

class _NoviosAdminScreenState extends State<NoviosAdminScreen> {
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _locationLabelController = TextEditingController();
  final MapController _mapController = MapController();
  bool _loading = false;
  bool _loadingLocation = false;
  bool _searching = false;
  String? _error;
  String? _locationError;
  List<Map<String, dynamic>> _searchResults = [];
  LatLng _selectedLocation = const LatLng(-33.4489, -70.6693);
  Map<String, dynamic>? _partyLocation;
  Map<String, dynamic>? _churchLocation;
  int _editingDestination = 1; // 0=Iglesia, 1=Fiesta
  bool _savingEventDate = false;
  String? _eventDateError;
  final EventJoinService _eventJoinService = EventJoinService();
  String _guestDirectionsTarget = 'both';
  bool _savingGuestDirections = false;
  String? _guestDirectionsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = context.read<UserContextProvider>();
      if (ctx.isAdmin) {
        _loadCurrentUrl();
        _loadCurrentLocation();
        _loadGuestDirections();
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _locationLabelController.dispose();
    super.dispose();
  }

  String _adminCode(String eventId) => '${eventId.toUpperCase()}-NOVIOS';

  void _moveMapToSelectedLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(_selectedLocation, 15);
    });
  }

  void _setSelectedLocation(
    double latitude,
    double longitude, {
    String? label,
    bool clearResults = true,
  }) {
    setState(() {
      _selectedLocation = LatLng(latitude, longitude);
      _latController.text = latitude.toStringAsFixed(6);
      _lngController.text = longitude.toStringAsFixed(6);
      if (label != null && label.trim().isNotEmpty) {
        _locationLabelController.text = label.trim();
      }
      if (clearResults) {
        _searchResults = [];
      }
      _locationError = null;
    });
    _moveMapToSelectedLocation();
  }

  Future<void> _loadCurrentUrl() async {
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    if (eventId.isEmpty) return;
    final url = await NoviosRegistryService().getRegistryUrl(eventId);
    if (!mounted) return;
    _urlController.text = url ?? '';
  }

  Future<void> _loadCurrentLocation() async {
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    if (eventId.isEmpty) return;
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final results = await Future.wait([
        NoviosRegistryService().getLocation(eventId),
        NoviosRegistryService().getChurchLocation(eventId),
      ]);
      final location = results[0];
      final church = results[1];
      if (!mounted) return;
      setState(() {
        _partyLocation = location;
        _churchLocation = church;
        if (_partyLocation == null && _churchLocation != null) {
          _editingDestination = 0;
        } else {
          _editingDestination = 1;
        }
      });
      final active = _editingDestination == 0 ? _churchLocation : _partyLocation;
      final latitude = active?['latitude'];
      final longitude = active?['longitude'];
      final label = (active?['label'] ?? '').toString();
      setState(() {
        if (latitude is num && longitude is num) {
          _selectedLocation = LatLng(latitude.toDouble(), longitude.toDouble());
          _latController.text = latitude.toString();
          _lngController.text = longitude.toString();
        } else {
          _latController.text = _selectedLocation.latitude.toString();
          _lngController.text = _selectedLocation.longitude.toString();
        }
        _locationLabelController.text = label;
      });
      _moveMapToSelectedLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = '$e');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _switchEditingDestination(int value) {
    setState(() {
      _editingDestination = value;
      _searchResults = [];
      _locationError = null;
    });
    final active = _editingDestination == 0 ? _churchLocation : _partyLocation;
    final latitude = active?['latitude'];
    final longitude = active?['longitude'];
    final label = (active?['label'] ?? '').toString();
    if (latitude is num && longitude is num) {
      _setSelectedLocation(latitude.toDouble(), longitude.toDouble(), label: label, clearResults: false);
    } else {
      _locationLabelController.text = label;
    }
  }

  Future<void> _loadGuestDirections() async {
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    if (eventId.isEmpty) return;
    try {
      final t = await NoviosRegistryService().getGuestDirectionsTarget(eventId);
      if (!mounted) return;
      setState(() => _guestDirectionsTarget = t);
    } catch (_) {
      if (mounted) setState(() => _guestDirectionsTarget = 'both');
    }
  }

  Future<void> _saveGuestDirections(String value) async {
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    if (eventId.isEmpty) return;
    final previous = _guestDirectionsTarget;
    setState(() {
      _guestDirectionsTarget = value;
      _savingGuestDirections = true;
      _guestDirectionsError = null;
    });
    try {
      await NoviosRegistryService().setGuestDirectionsTarget(
        eventId: eventId,
        adminCode: _adminCode(eventId),
        target: value,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencia de “Cómo llegar” guardada ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guestDirectionsTarget = previous;
        _guestDirectionsError = '$e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingGuestDirections = false);
    }
  }

  Future<void> _pickAndSaveEventDateTime() async {
    final ctx = context.read<UserContextProvider>();
    final initial = ctx.eventDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted || pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || pickedTime == null) return;
    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    await _saveEventDateTime(combined);
  }

  Future<void> _saveEventDateTime(DateTime dt) async {
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    if (eventId.isEmpty) return;
    setState(() {
      _savingEventDate = true;
      _eventDateError = null;
    });
    String? cloudErr;
    try {
      try {
        await _eventJoinService
            .mergeEventDate(eventId: eventId, date: dt)
            .timeout(const Duration(seconds: 25));
      } on TimeoutException {
        cloudErr = 'La sincronización con Firebase tardó demasiado. Revisá la conexión o las reglas.';
      } catch (e) {
        cloudErr = '$e';
      }
      await ctx.updateEventDate(dt);
    } finally {
      if (mounted) {
        setState(() {
          _savingEventDate = false;
          if (cloudErr != null) _eventDateError = cloudErr;
        });
      }
    }
    if (!mounted) return;
    if (cloudErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guardado en este dispositivo. No se pudo sincronizar con Firebase: $cloudErr',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha y hora del evento guardadas ✅')),
      );
    }
  }

  Future<void> _saveUrl() async {
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final url = _urlController.text.trim();
    if (eventId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await NoviosRegistryService().setRegistryUrl(
        eventId: eventId,
        adminCode: _adminCode(eventId),
        registryUrl: url,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista guardada ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveLocation() async {
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final label = _locationLabelController.text.trim();
    if (eventId.isEmpty) return;
    if (lat == null || lng == null) {
      setState(() => _locationError = 'Debes ingresar coordenadas válidas');
      return;
    }
    _setSelectedLocation(lat, lng, label: label, clearResults: false);
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final svc = NoviosRegistryService();
      if (_editingDestination == 0) {
        await svc.setChurchLocation(
          eventId: eventId,
          adminCode: _adminCode(eventId),
          latitude: lat,
          longitude: lng,
          label: label,
        );
        _churchLocation = {
          'latitude': lat,
          'longitude': lng,
          'label': label,
        };
      } else {
        await svc.setLocation(
          eventId: eventId,
          adminCode: _adminCode(eventId),
          latitude: lat,
          longitude: lng,
          label: label,
        );
        _partyLocation = {
          'latitude': lat,
          'longitude': lng,
          'label': label,
        };
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingDestination == 0 ? 'Ubicación de iglesia guardada ✅' : 'Ubicación de fiesta guardada ✅',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = '$e');
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _locationError = 'Escribe un lugar para buscar');
      return;
    }

    setState(() {
      _searching = true;
      _locationError = null;
      _searchResults = [];
    });

    try {
      final results = await NoviosRegistryService().searchLocation(query: query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = '$e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final isAdmin = ctx.isAdmin;

    return NestedFlowNavigator(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Row(
            children: [
              const Text('👰🤵 '),
              Text('Panel de novios', style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
            ],
          ),
          leading: IconButton(
            onPressed: () => popOrEntry(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: ListView(
            children: [
            if (eventId.isEmpty) ...[
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Debes unirte a un evento primero.', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.x1),
                    Text('Luego podrás editar la lista y la ubicación.', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.x2),
                    CustomButton(
                      label: 'Volver',
                      onPressed: () => popOrEntry(context),
                    ),
                  ],
                ),
              ),
            ] else ...[
              if (!isAdmin) ...[
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Este panel solo está disponible si te unes con el código de novios.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Tip: usa "$eventId-NOVIOS" al unirte al evento.',
                        style: AppTextStyles.title.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.x2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: AppRadii.card,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: AppColors.primaryDark, size: 22),
                      const SizedBox(width: AppSpacing.x1_5),
                      Expanded(
                        child: Text(
                          'Aquí puedes configurar la información que verán tus invitados.',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📅 ', style: TextStyle(fontSize: 18)),
                          Text('Fecha y hora del evento', style: AppTextStyles.title),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Es la hora de inicio que verán los invitados al usar “Añadir a mi calendario” (Google Calendar, etc.).',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        ctx.eventDate == null
                            ? 'Todavía no hay fecha en este dispositivo.'
                            : 'Configurado: ${DateFormat('dd/MM/yyyy HH:mm').format(ctx.eventDate!)}',
                        style: AppTextStyles.title.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      CustomButton(
                        label: _savingEventDate ? 'Guardando...' : 'Elegir fecha y hora',
                        icon: Icons.event_available_outlined,
                        loading: _savingEventDate,
                        onPressed: _savingEventDate ? null : _pickAndSaveEventDateTime,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🎁 ', style: TextStyle(fontSize: 18)),
                          Text('Lista de regalos', style: AppTextStyles.title),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Pega el link de la lista de regalos (Falabella/Paris/Ripley o cualquier URL).',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Link lista de novios',
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_loading) _saveUrl();
                        },
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      CustomButton(
                        label: _loading ? 'Guardando...' : 'Guardar link',
                        icon: _loading ? Icons.hourglass_bottom : Icons.save,
                        loading: _loading,
                        onPressed: _loading ? null : _saveUrl,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🧭 ', style: TextStyle(fontSize: 18)),
                          Text('Cómo llegar (invitados)', style: AppTextStyles.title),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Elegí qué dirección ven en “Cómo llegar”. Si solo configuraste una, igual podés dejar “Solo ceremonia” o “Solo fiesta”.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'ceremony',
                            label: Text('Solo ceremonia'),
                          ),
                          ButtonSegment<String>(
                            value: 'venue',
                            label: Text('Solo fiesta'),
                          ),
                          ButtonSegment<String>(
                            value: 'both',
                            label: Text('Ambas'),
                          ),
                        ],
                        selected: <String>{_guestDirectionsTarget},
                        onSelectionChanged: _savingGuestDirections
                            ? (_) {}
                            : (Set<String> next) => _saveGuestDirections(next.first),
                      ),
                      if (_savingGuestDirections) ...[
                        const SizedBox(height: AppSpacing.x1),
                        const LinearProgressIndicator(),
                      ],
                      if (_guestDirectionsError != null) ...[
                        const SizedBox(height: AppSpacing.x1),
                        Text(_guestDirectionsError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📍 ', style: TextStyle(fontSize: 18)),
                          Text('Ubicaciones', style: AppTextStyles.title),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Configura la ubicación de la iglesia y de la fiesta.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment<int>(value: 0, label: Text('Iglesia')),
                          ButtonSegment<int>(value: 1, label: Text('Fiesta')),
                        ],
                        selected: <int>{_editingDestination},
                        onSelectionChanged: (s) => _switchEditingDestination(s.first),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar lugar o dirección',
                          prefixIcon: Icon(Icons.search),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          if (!_searching) _searchLocation();
                        },
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      CustomButton(
                        label: _searching ? 'Buscando...' : 'Buscar',
                        icon: Icons.search,
                        loading: _searching,
                        onPressed: _searching ? null : _searchLocation,
                      ),
                      if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x2),
                        Text('Resultados', style: AppTextStyles.title.copyWith(fontSize: 14)),
                        const SizedBox(height: AppSpacing.x1),
                        ..._searchResults.map((result) {
                          final label = (result['label'] ?? '').toString();
                          final latitude = result['latitude'];
                          final longitude = result['longitude'];
                          if (latitude is! num || longitude is! num) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.x1),
                            child: CustomCard(
                              onTap: () => _setSelectedLocation(
                                latitude.toDouble(),
                                longitude.toDouble(),
                                label: label,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.x1_5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label.isNotEmpty ? label : 'Lugar sin nombre',
                                    style: AppTextStyles.title.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${latitude.toDouble().toStringAsFixed(6)}, ${longitude.toDouble().toStringAsFixed(6)}',
                                    style: AppTextStyles.subtitle,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selecciona el punto', style: AppTextStyles.title),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        _editingDestination == 0
                            ? 'Toca el mapa para fijar el punto exacto de la iglesia.'
                            : 'Toca el mapa para fijar el punto exacto de la fiesta.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      SizedBox(
                        height: 280,
                        child: ClipRRect(
                          borderRadius: AppRadii.card,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _selectedLocation,
                              initialZoom: 15,
                              onTap: (tapPosition, point) {
                                _setSelectedLocation(point.latitude, point.longitude, clearResults: false);
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.wedding_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation,
                                    width: 48,
                                    height: 48,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppColors.primary,
                                      size: 48,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Coordenadas actuales: ${_latController.text.isEmpty ? '--' : _latController.text}, ${_lngController.text.isEmpty ? '--' : _lngController.text}',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      TextField(
                        controller: _locationLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del lugar (opcional)',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.x1_5),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latController,
                              decoration: const InputDecoration(
                                labelText: 'Latitud',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_locationError != null) {
                                  setState(() => _locationError = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x1_5),
                          Expanded(
                            child: TextField(
                              controller: _lngController,
                              decoration: const InputDecoration(
                                labelText: 'Longitud',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_loadingLocation) _saveLocation();
                              },
                              onChanged: (_) {
                                if (_locationError != null) {
                                  setState(() => _locationError = null);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      CustomButton(
                        label: _loadingLocation
                            ? 'Guardando...'
                            : (_editingDestination == 0
                                ? 'Guardar ubicación iglesia'
                                : 'Guardar ubicación fiesta'),
                        icon: _loadingLocation ? Icons.hourglass_bottom : Icons.place_outlined,
                        loading: _loadingLocation,
                        onPressed: _loadingLocation ? null : _saveLocation,
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_locationError != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(_locationError!, style: const TextStyle(color: Colors.red)),
            ],
            if (_eventDateError != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(_eventDateError!, style: const TextStyle(color: Colors.red)),
            ],
            if (_loadingLocation) ...[
              const SizedBox(height: AppSpacing.x2),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
      ),
    );
  }
}


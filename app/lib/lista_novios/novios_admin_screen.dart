import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = context.read<UserContextProvider>();
      if (ctx.isAdmin) {
        _loadCurrentUrl();
        _loadCurrentLocation();
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
      final location = await NoviosRegistryService().getLocation(eventId);
      if (!mounted) return;
      final latitude = location?['latitude'];
      final longitude = location?['longitude'];
      final label = (location?['label'] ?? '').toString();
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
      await NoviosRegistryService().setLocation(
        eventId: eventId,
        adminCode: _adminCode(eventId),
        latitude: lat,
        longitude: lng,
        label: label,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación guardada ✅')),
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
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: AppRadii.card,
                    border: Border.all(color: AppColors.primary.withOpacity(0.15)),
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
                          const Text('📍 ', style: TextStyle(fontSize: 18)),
                          Text('Ubicación del evento', style: AppTextStyles.title),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Busca el lugar, toca el mapa o ajusta las coordenadas manualmente.',
                        style: AppTextStyles.subtitle,
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
                        'Toca el mapa para fijar el punto exacto del evento.',
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
                        label: _loadingLocation ? 'Guardando...' : 'Guardar ubicación',
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


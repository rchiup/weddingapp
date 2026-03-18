import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../ui/custom_card.dart';
import '../user_context/user_context_provider.dart';
import 'novios_registry_service.dart';

class NoviosAdminScreen extends StatefulWidget {
  const NoviosAdminScreen({super.key});

  @override
  State<NoviosAdminScreen> createState() => _NoviosAdminScreenState();
}

class _NoviosAdminScreenState extends State<NoviosAdminScreen> {
  final _urlController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _locationLabelController = TextEditingController();
  bool _loading = false;
  bool _loadingLocation = false;
  String? _error;
  String? _locationError;

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
    _latController.dispose();
    _lngController.dispose();
    _locationLabelController.dispose();
    super.dispose();
  }

  String _adminCode(String eventId) => '${eventId.toUpperCase()}-NOVIOS';

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
      setState(() {
        _latController.text = latitude is num ? latitude.toString() : '';
        _lngController.text = longitude is num ? longitude.toString() : '';
        _locationLabelController.text = (location?['label'] ?? '').toString();
      });
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

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final isAdmin = ctx.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de novios'),
        leading: IconButton(
          onPressed: () => context.go('/entry'),
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
                      onPressed: () => context.go('/entry'),
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
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lista de regalos', style: AppTextStyles.title),
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
                      Text('Ubicación del evento', style: AppTextStyles.title),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Ingresa coordenadas para generar el link de Waze que verán los invitados.',
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
    );
  }
}


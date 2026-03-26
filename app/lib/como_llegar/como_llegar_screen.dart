import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../lista_novios/novios_registry_service.dart';
import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../ui/custom_card.dart';
import '../user_context/user_context_provider.dart';
import '../utils/nav_safe.dart';
import '../utils/nested_flow_navigator.dart';

class ComoLlegarScreen extends StatefulWidget {
  const ComoLlegarScreen({super.key});

  @override
  State<ComoLlegarScreen> createState() => _ComoLlegarScreenState();
}

class _ComoLlegarScreenState extends State<ComoLlegarScreen> {
  final NoviosRegistryService _service = NoviosRegistryService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _location;
  Map<String, dynamic>? _churchLocation;
  int _selectedDestination = 1; // 0=Iglesia, 1=Fiesta
  /// venue | ceremony | both (lo definen los novios en el panel).
  String _guestTarget = 'both';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocation());
  }

  bool _hasValidCoords(Map<String, dynamic>? m) {
    if (m == null) return false;
    return m['latitude'] is num && m['longitude'] is num;
  }

  bool get _hasChurch => _hasValidCoords(_churchLocation);
  bool get _hasParty => _hasValidCoords(_location);

  bool get _showSelector => _hasChurch && _hasParty && _guestTarget == 'both';

  Map<String, dynamic>? get _effectiveGuestLocation {
    if (_showSelector) {
      return _selectedDestination == 0 ? _churchLocation : _location;
    }
    if (_guestTarget == 'venue') {
      if (_hasParty) return _location;
      if (_hasChurch) return _churchLocation;
      return null;
    }
    if (_guestTarget == 'ceremony') {
      if (_hasChurch) return _churchLocation;
      if (_hasParty) return _location;
      return null;
    }
    if (_hasParty && _hasChurch) {
      return _selectedDestination == 0 ? _churchLocation : _location;
    }
    if (_hasParty) return _location;
    if (_hasChurch) return _churchLocation;
    return null;
  }

  Uri? _wazeUri(Map<String, dynamic>? location) {
    if (location == null) return null;
    final latitude = location['latitude'];
    final longitude = location['longitude'];
    if (latitude is! num || longitude is! num) return null;
    final rawUrl = location['wazeUrl']?.toString();
    return Uri.parse(
      rawUrl != null && rawUrl.isNotEmpty
          ? rawUrl
          : 'https://waze.com/ul?ll=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}&navigate=yes',
    );
  }

  Future<void> _loadLocation() async {
    final eventId = context.read<UserContextProvider>().eventId ?? '';
    if (eventId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _location = null;
        _churchLocation = null;
      });
      return;
    }
    try {
      final results = await Future.wait([
        _service.getLocation(eventId),
        _service.getChurchLocation(eventId),
        _service.getGuestDirectionsTarget(eventId),
      ]);
      final location = results[0] as Map<String, dynamic>?;
      final church = results[1] as Map<String, dynamic>?;
      final target = results[2] as String;
      if (!mounted) return;
      setState(() {
        _location = location;
        _churchLocation = church;
        _guestTarget = target;
        _error = null;
        if (_location == null && _churchLocation != null) {
          _selectedDestination = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openWaze() async {
    final uri = _wazeUri(_effectiveGuestLocation);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _destinationTitle() {
    if (_showSelector) {
      return _selectedDestination == 0 ? 'Iglesia' : 'Fiesta';
    }
    switch (_guestTarget) {
      case 'ceremony':
        return 'Ceremonia';
      case 'venue':
        return 'Fiesta / recepción';
      default:
        return 'Destino';
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventName = context.watch<UserContextProvider>().eventName ?? 'Evento';
    final location = _effectiveGuestLocation;
    final label = (location?['label'] ?? '').toString().trim();
    final latitude = location?['latitude'];
    final longitude = location?['longitude'];
    final hasCoords = latitude is num && longitude is num;

    return NestedFlowNavigator(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cómo llegar'),
          leading: IconButton(
            onPressed: () => popOrEntry(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  CustomCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.directions_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.x1_5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cómo llegar a $eventName', style: AppTextStyles.title.copyWith(fontSize: 16)),
                              const SizedBox(height: AppSpacing.x1),
                              Text(
                                hasCoords
                                    ? 'Abre Waze con la ubicación del evento.'
                                    : 'Aún no configuraron la ubicación.',
                                style: AppTextStyles.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showSelector) ...[
                    const SizedBox(height: AppSpacing.x2),
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Destino', style: AppTextStyles.title.copyWith(fontSize: 14)),
                          const SizedBox(height: AppSpacing.x1),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment<int>(value: 0, label: Text('Iglesia')),
                              ButtonSegment<int>(value: 1, label: Text('Fiesta')),
                            ],
                            selected: <int>{_selectedDestination},
                            onSelectionChanged: (s) {
                              setState(() => _selectedDestination = s.first);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.x2),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: AppSpacing.x2),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _destinationTitle(),
                          style: AppTextStyles.title.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          label.isNotEmpty ? label : 'Ubicación sin nombre',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          hasCoords
                              ? 'Lat: ${latitude.toStringAsFixed(6)}  •  Lng: ${longitude.toStringAsFixed(6)}'
                              : 'Coordenadas no configuradas',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        CustomButton(
                          label: 'Abrir Waze',
                          icon: Icons.navigation_outlined,
                          onPressed: hasCoords ? _openWaze : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Si Waze no se abre, se abrirá en el navegador con la misma ruta.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

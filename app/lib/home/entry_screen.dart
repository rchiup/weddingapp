import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../checkin/checkin_eligibility.dart';
import '../checkin/checkin_service.dart';
import '../event_join/event_join_provider.dart';
import '../event_join/event_join_screen.dart';
import '../lista_novios/novios_registry_service.dart';
import '../solteros/solteros_service.dart';
import '../solteros/solteros_provider.dart';
import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../user_context/user_context_provider.dart';
import 'event_countdown.dart';

/// Pantalla de entrada neutral
///
/// Permite elegir intención: conocer gente o subir/ver fotos.
/// No contiene lógica de negocio, solo navegación a flujos.
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  bool _nameDialogShown = false;
  bool _singleDialogShown = false;
  bool _locationDialogShown = false;
  final SolterosService _solterosService = SolterosService();
  final CheckinService _checkinService = CheckinService();

  static const String _createEventUrl = 'https://weddingapp-c6ix.onrender.com';

  Future<void> _openCreateEvent() async {
    final uri = Uri.tryParse(_createEventUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  final NoviosRegistryService _registryService = NoviosRegistryService();
  String? _trackedEventId;
  String? _coupleNames;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<UserContextProvider>().eventId;
    if (id != _trackedEventId) {
      _trackedEventId = id;
      _nameDialogShown = false;
      _singleDialogShown = false;
      _locationDialogShown = false;
      _coupleNames = null;
      if (id != null && id.trim().isNotEmpty) {
        _loadCoupleNames(id.trim());
      }
    }
  }

  Future<void> _loadCoupleNames(String eventId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('settings')
          .doc('public')
          .get();
      final data = doc.data() ?? {};
      final names = (data['coupleNames'] ?? '').toString().trim();
      if (!mounted) return;
      setState(() => _coupleNames = names.isEmpty ? null : names);
    } catch (_) {
      // silencioso
    }
  }

  String _eventDateLine(UserContextProvider ctx) {
    final d = ctx.eventDate;
    if (d == null) return '';
    return DateFormat('yyyy-MM-dd').format(d);
  }

  String _eventDatePretty(UserContextProvider ctx) {
    final d = ctx.eventDate;
    if (d == null) return '17 Enero 2026';
    return DateFormat('dd MMMM yyyy', 'es').format(d);
  }

  String _eventTitle(UserContextProvider ctx) {
    final fromPanel = (_coupleNames ?? '').trim();
    if (fromPanel.isNotEmpty) return fromPanel;
    final raw = (ctx.eventName ?? '').trim();
    if (raw.isEmpty) return 'Carolina & Nicolás';
    // Si viene como "Evento XYZ", lo evitamos (look marketplace).
    final lower = raw.toLowerCase();
    if (lower.startsWith('evento ')) {
      return raw.substring(6).trim();
    }
    return raw;
  }

  Future<void> _confirmExitEvent(BuildContext context, UserContextProvider userContext) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir del evento'),
        content: const Text('¿Volver al inicio? Podrás ingresar de nuevo con el código.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await userContext.clearEvent();
    }
  }

  void _maybeAskName(BuildContext context, UserContextProvider userContext) {
    final hasEvent = userContext.eventId != null && userContext.eventId!.isNotEmpty;
    final noName = userContext.userName == null || userContext.userName!.trim().isEmpty;
    if (!hasEvent || !noName || _nameDialogShown || userContext.isAdmin) return;
    _nameDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      _showNameDialog(context, userContext);
    });
  }

  void _maybeAskLocation(BuildContext context, UserContextProvider userContext) {
    final eventId = userContext.eventId ?? '';
    final userId = userContext.userId ?? '';
    final hasName = (userContext.userName ?? '').trim().isNotEmpty;
    final singleDecided = userContext.isSingleForCurrentEvent || userContext.declinedSingleForCurrentEvent;
    // Novios: nunca pedimos ubicación en el home.
    if (eventId.isEmpty || userId.isEmpty) return;
    if (userContext.isAdmin) return;
    if (!userContext.isAdmin) {
      if (!hasName) return;
      if (!singleDecided) return;
    }
    if (_locationDialogShown) return;
    if (userContext.locationPromptedForCurrentEvent) return;
    if (userContext.autoCheckinDoneForCurrentEvent) return;

    _locationDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      () async {
        // Si ya tiene permisos de ubicación activos, no volvemos a pedirlos.
        final locationEnabled = await Geolocator.isLocationServiceEnabled();
        if (locationEnabled) {
          final permission = await Geolocator.checkPermission();
          final alreadyGranted = permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
          if (alreadyGranted) {
            await userContext.markLocationPromptedForEvent(eventId);
            await _tryAutoCheckin(userContext, requestIfDenied: false);
            return;
          }
        }
        // Si ya llegó (manual o por otra sesión), no molestamos con el prompt.
        final alreadyArrived = await _checkinService.hasArrived(eventId: eventId, userId: userId);
        if (!context.mounted) return;
        if (alreadyArrived) {
          await userContext.markAutoCheckinDoneForEvent(eventId);
          await userContext.markLocationPromptedForEvent(eventId);
          return;
        }
        await _showLocationDialog(context, userContext);
      }();
    });
  }

  Future<void> _showLocationDialog(BuildContext context, UserContextProvider userContext) async {
    final eventId = userContext.eventId ?? '';
    if (eventId.isEmpty) return;

    // Marcamos como "ya preguntado" para no spamear cada vez que abre la app.
    await userContext.markLocationPromptedForEvent(eventId);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Activa tu ubicación'),
          content: const Text(
            'Activa la ubicación si quieres ver quién más ya llegó.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'No activar',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.x1_5),
                Expanded(
                  child: CustomButton(
                    label: 'Activar',
                    icon: Icons.my_location,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _tryAutoCheckin(userContext, requestIfDenied: true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tryAutoCheckin(
    UserContextProvider userContext, {
    required bool requestIfDenied,
  }) async {
    final eventId = userContext.eventId ?? '';
    final userId = userContext.userId ?? '';
    if (eventId.isEmpty || userId.isEmpty) return;
    if (userContext.autoCheckinDoneForCurrentEvent) return;

    try {
      final alreadyArrived = await _checkinService.hasArrived(eventId: eventId, userId: userId);
      if (alreadyArrived) {
        await userContext.markAutoCheckinDoneForEvent(eventId);
        return;
      }

      final location = await _registryService.getLocation(eventId);
      final latitude = location?['latitude'];
      final longitude = location?['longitude'];
      if (latitude is! num || longitude is! num) return;

      if (!isCheckinEventDay(userContext.eventDate)) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestIfDenied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude.toDouble(),
        longitude.toDouble(),
      );
      if (distance > checkInRadiusMeters) return;

      final name = userContext.userName ?? 'Invitado';
      await _checkinService.checkIn(eventId: eventId, userId: userId, name: name);
      await userContext.markAutoCheckinDoneForEvent(eventId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Llegada marcada automáticamente ✅')),
      );
    } catch (_) {
      // Silencioso: no queremos bloquear el arranque por permisos/errores.
    }
  }

  void _maybeAskSingle(BuildContext context, UserContextProvider userContext) {
    final hasEvent = userContext.eventId != null && userContext.eventId!.isNotEmpty;
    final hasName = userContext.userName != null && userContext.userName!.trim().isNotEmpty;
    if (!hasEvent || !hasName || userContext.isAdmin) return;
    if (userContext.isSingleForCurrentEvent || userContext.declinedSingleForCurrentEvent) return;
    if (_singleDialogShown) return;
    _singleDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      _showSingleQuestionDialog(context, userContext);
    });
  }

  Future<void> _showNameDialog(BuildContext context, UserContextProvider userContext) async {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    String? errorText;
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> submit() async {
            final first = firstNameController.text.trim();
            final last = lastNameController.text.trim();
            if (first.isEmpty || last.isEmpty) {
              setState(() => errorText = 'Nombre y apellido son obligatorios');
              return;
            }
            final fullName = '$first $last';
            await userContext.setUserName(fullName);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (context.mounted) _maybeAskSingle(context, userContext);
          }

          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('¿Cómo te llamas?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      hintText: 'Nombre',
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (errorText != null) setState(() => errorText = null);
                    },
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Apellido',
                      errorText: errorText,
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    onChanged: (_) {
                      if (errorText != null) setState(() => errorText = null);
                    },
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(label: 'Guardar', onPressed: submit),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSingleQuestionDialog(
    BuildContext context,
    UserContextProvider userContext,
  ) async {
    final eventId = userContext.eventId ?? '';
    if (eventId.trim().isEmpty) return;

    final isSingle = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('¿Estás soltero/a?'),
            content: const Text('Responde con Sí o No para continuar.'),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'No',
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1_5),
                  Expanded(
                    child: CustomButton(
                      label: 'Sí',
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (isSingle != true) {
      await userContext.declineSingleForEvent(eventId);
      if (context.mounted) _maybeAskLocation(context, userContext);
      return;
    }

    // Segunda pantalla: decidir si quiere aparecer en la lista de solteros.
    await _showSingleListDialog(context, userContext);
    if (context.mounted) _maybeAskLocation(context, userContext);
  }

  Future<void> _showSingleListDialog(
    BuildContext context,
    UserContextProvider userContext,
  ) async {
    final eventId = userContext.eventId ?? '';
    final userId = userContext.userId ?? '';
    final name = (userContext.userName ?? '').trim();
    if (eventId.trim().isEmpty || userId.isEmpty || name.isEmpty) return;

    final joinList = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('¿Aparecer en la lista de solteros?'),
            content: const Text(
              'La lista de solteros es para interactuar y chatear con otras personas solteras del evento.',
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'No',
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1_5),
                  Expanded(
                    child: CustomButton(
                      label: 'Sí',
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (joinList != true) {
      // No quiere aparecer ni que se le vuelva a preguntar.
      await userContext.declineSingleForEvent(eventId);
      if (context.mounted) _maybeAskLocation(context, userContext);
      return;
    }

    try {
      await _solterosService.activateSingle(eventId: eventId, userId: userId, name: name);
      await userContext.activateSingleForEvent(eventId);
    } catch (_) {
      // Silencioso para demo.
    }
    if (context.mounted) _maybeAskLocation(context, userContext);
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final solteros = context.watch<SolterosProvider>();
    final hasEvent = userContext.eventId != null && userContext.eventId!.isNotEmpty;
    _maybeAskName(context, userContext);
    _maybeAskSingle(context, userContext);
    _maybeAskLocation(context, userContext);

    if (!hasEvent) {
      return Scaffold(
        backgroundColor: AppColors.joinLanding,
        body: SafeArea(
          child: ChangeNotifierProvider(
            create: (_) => EventJoinProvider(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2, vertical: AppSpacing.x2),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.x2 * 2),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: const EventJoinScreen(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    final dateLine = _eventDateLine(userContext);
    final roleLine = userContext.isAdmin ? 'Modo novios' : 'Invitado';
    final subtitleHeader = [if (dateLine.isNotEmpty) dateLine, roleLine].join(' · ');

    final menuItems = <_MenuItem>[
      _MenuItem(
        label: 'Revive el momento',
        imageUrl:
            'https://images.unsplash.com/photo-1523438097201-512ae7d59c71?auto=format&fit=crop&w=1200&q=80',
        onTap: () => context.push('/fotos'),
      ),
      _MenuItem(
        label: 'Quién está acá',
        imageUrl:
            'https://images.unsplash.com/photo-1529655683826-aba9b3e77383?auto=format&fit=crop&w=1200&q=80',
        onTap: () => context.push('/checkin'),
      ),
      _MenuItem(
        label: 'Cómo llegar',
        imageUrl:
            'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=1200&q=80',
        onTap: () => context.push('/como_llegar'),
      ),
      if (userContext.isSingleForCurrentEvent)
        _MenuItem(
          label: 'Solteros',
          imageUrl:
              'https://images.unsplash.com/photo-1520034475321-cbe63696469a?auto=format&fit=crop&w=1200&q=80',
          onTap: () => context.push('/solteros/chats'),
          showBadge: solteros.hasAnyUnread,
        ),
      _MenuItem(
        label: 'Busca tu mesa',
        imageUrl:
            'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=1200&q=80',
        onTap: () => context.push('/mesas'),
      ),
      _MenuItem(
        label: 'Regalos',
        imageUrl:
            'https://images.unsplash.com/photo-1513279922550-250c2129b13a?auto=format&fit=crop&w=1200&q=80',
        onTap: () => context.push('/lista_novios'),
      ),
      _MenuItem(
        label: 'Confirma tu asistencia',
        imageUrl:
            'https://images.unsplash.com/photo-1529619768328-e3f2f8bb2f7f?auto=format&fit=crop&w=1200&q=80',
        onTap: () => context.push('/rsvp'),
      ),
      _MenuItem(
        label: 'Canciones infaltables',
        imageUrl:
            'https://images.unsplash.com/photo-1497032205916-ac775f0649ae?auto=format&fit=crop&w=1200&q=80',
        onTap: () => context.push('/songs'),
      ),
      _MenuItem(
        label: 'Añadir a mi calendario',
        imageUrl:
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
        onTap: () => context.push('/calendar'),
      ),
      if (userContext.isAdmin)
        _MenuItem(
          label: 'Panel de novios',
          imageUrl:
              'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
          onTap: () => context.push('/novios_admin'),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, page) {
            final pageWide = page.maxWidth >= 760;
            final heroHeight = hasEvent ? (pageWide ? 380.0 : 310.0) : 0.0;
            return Stack(
              children: [
                if (hasEvent)
                  Positioned(
                    top: AppSpacing.x2,
                    left: AppSpacing.x2,
                    right: AppSpacing.x2,
                    child: ClipRRect(
                      borderRadius: AppRadii.card,
                      child: SizedBox(
                        height: heroHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=1600&q=80',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0xFFD9D1C6), Color(0xFFB9C1B4)],
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.48),
                                    Colors.white.withValues(alpha: 0.62),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: pageWide ? 56 : 30,
                                vertical: 28,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'SAVE THE DATE',
                                    style: AppTextStyles.subtitle.copyWith(
                                      letterSpacing: 3.0,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _eventTitle(userContext),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.display.copyWith(
                                      fontSize: pageWide ? 62 : 44,
                                      height: 1.02,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    width: pageWide ? 280 : 220,
                                    height: 1,
                                    color: AppColors.border.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _eventDatePretty(userContext),
                                    style: AppTextStyles.title.copyWith(
                                      fontSize: pageWide ? 24 : 20,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nos casamos',
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontSize: pageWide ? 16 : 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  EventCountdownChip(eventDate: userContext.eventDate),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitleHeader,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.x2,
                          hasEvent ? heroHeight + (AppSpacing.x2 * 2) : AppSpacing.x2,
                          AppSpacing.x2,
                          AppSpacing.x3,
                        ),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          LayoutBuilder(
                            builder: (context, c) {
                              final w = c.maxWidth;
                              final crossAxisCount = w >= 500 ? 3 : 2;
                              const spacing = 18.0;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: menuItems.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: spacing,
                                  crossAxisSpacing: spacing,
                                  childAspectRatio: crossAxisCount >= 3 ? 1.0 : 0.96,
                                ),
                                itemBuilder: (context, i) {
                                  return _MenuGridCard(item: menuItems[i]);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.x2),
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.9))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.local_florist_outlined,
                                  size: 18,
                                  color: AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                              ),
                              Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.9))),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x1_5),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: _openCreateEvent,
                                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                                  label: const Text('Crea tu propio evento'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textMuted,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _confirmExitEvent(context, userContext),
                                  icon: const Icon(Icons.logout_rounded, size: 20),
                                  label: const Text('Salir del evento'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final String imageUrl;
  final VoidCallback? onTap;
  final bool showBadge;

  _MenuItem({
    required this.label,
    required this.imageUrl,
    this.onTap,
    this.showBadge = false,
  });
}

class _MenuGridCard extends StatefulWidget {
  final _MenuItem item;

  const _MenuGridCard({required this.item});

  @override
  State<_MenuGridCard> createState() => _MenuGridCardState();
}

class _MenuGridCardState extends State<_MenuGridCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final enabled = item.onTap != null;

    final radius = BorderRadius.circular(26);

    final imageCard = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF2F3A3D), Color(0xFF8C9A95)],
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.black.withValues(alpha: 0.18),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.displaySmall.copyWith(
                  fontSize: 20,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
                  ],
                ),
              ),
            ),
          ),
          if (item.showBadge && enabled)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.25), width: 1),
                ),
              ),
            ),
        ],
      ),
    );

    final core = AnimatedScale(
      scale: enabled && _hover ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: enabled && _hover ? 0.14 : 0.10),
                    blurRadius: enabled && _hover ? 26 : 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : AppShadows.soft,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? item.onTap : null,
            child: imageCard,
          ),
        ),
      ),
    );

    final withHover = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (!enabled) return;
        setState(() => _hover = true);
      },
      onExit: (_) {
        if (!enabled) return;
        setState(() => _hover = false);
      },
      child: core,
    );

    if (enabled) return withHover;

    return Opacity(
      opacity: 0.48,
      child: IgnorePointer(child: withHover),
    );
  }
}

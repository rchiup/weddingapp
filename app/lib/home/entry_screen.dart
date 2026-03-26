import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../ui/custom_card.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<UserContextProvider>().eventId;
    if (id != _trackedEventId) {
      _trackedEventId = id;
      _nameDialogShown = false;
      _singleDialogShown = false;
      _locationDialogShown = false;
    }
  }

  String _eventDateLine(UserContextProvider ctx) {
    final d = ctx.eventDate;
    if (d == null) return '';
    return DateFormat('yyyy-MM-dd').format(d);
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
    // Admins (novios) no pasan por nombre/solteros, así que pueden ver el prompt directo.
    if (eventId.isEmpty || userId.isEmpty) return;
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
                      await _tryAutoCheckin(userContext);
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

  Future<void> _tryAutoCheckin(UserContextProvider userContext) async {
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
      if (permission == LocationPermission.denied) {
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
    final roleLine = userContext.isAdmin ? '👑 Modo Novios' : 'Invitado';
    final subtitleHeader = [if (dateLine.isNotEmpty) dateLine, roleLine].join(' · ');

    final menuItems = <_MenuItem>[
      _MenuItem(
        emoji: '📸',
        icon: Icons.photo_camera_outlined,
        label: 'Fotos del evento',
        onTap: () => context.push('/fotos'),
      ),
      _MenuItem(
        emoji: '🎉',
        icon: Icons.celebration_outlined,
        label: 'Ver quién llegó',
        onTap: () => context.push('/checkin'),
      ),
      _MenuItem(
        emoji: '🗺️',
        icon: Icons.place_outlined,
        label: 'Cómo llegar',
        onTap: () => context.push('/como_llegar'),
      ),
      if (userContext.isSingleForCurrentEvent)
        _MenuItem(
          emoji: '💘',
          icon: Icons.favorite_border,
          label: 'Solteros',
          onTap: () => context.push('/solteros/chats'),
          showBadge: solteros.hasAnyUnread,
        ),
      _MenuItem(
        emoji: '👥',
        icon: Icons.people_outline,
        label: 'Invitados',
        onTap: () => context.push('/mesas'),
      ),
      _MenuItem(
        emoji: '🎁',
        icon: Icons.card_giftcard_outlined,
        label: 'Lista de novios',
        onTap: () => context.push('/lista_novios'),
      ),
      _MenuItem(
        emoji: '✅',
        icon: Icons.fact_check_outlined,
        label: 'RSVP',
        onTap: () => context.push('/rsvp'),
      ),
      _MenuItem(
        emoji: '🎵',
        icon: Icons.library_music_outlined,
        label: 'Canciones infaltables',
        onTap: () => context.push('/songs'),
      ),
      _MenuItem(
        emoji: '📅',
        icon: Icons.calendar_month_outlined,
        label: 'Añadir a mi calendario',
        onTap: () => context.push('/calendar'),
      ),
      if (userContext.isAdmin)
        _MenuItem(
          emoji: '👰🤵',
          icon: Icons.workspace_premium_outlined,
          label: 'Panel de novios',
          onTap: () => context.push('/novios_admin'),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasEvent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(AppSpacing.x2, 26, AppSpacing.x2, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.accentHeaderStart,
                      AppColors.accentHeaderEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x28000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      userContext.eventName ?? 'Tu evento',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    EventCountdownChip(eventDate: userContext.eventDate),
                    const SizedBox(height: 8),
                    Text(
                      subtitleHeader,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                color: AppColors.menuBackground,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x2,
                        AppSpacing.x2,
                        AppSpacing.x2,
                        AppSpacing.x3,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth;
                            final crossAxisCount = w >= 500 ? 3 : 2;
                            const spacing = 14.0;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: menuItems.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                childAspectRatio: crossAxisCount >= 3 ? 0.9 : 0.88,
                              ),
                              itemBuilder: (context, i) {
                                return _MenuGridCard(item: menuItems[i]);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        const Divider(),
                        const SizedBox(height: AppSpacing.x1),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String emoji;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showBadge;

  _MenuItem({
    required this.emoji,
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.showBadge = false,
  });
}

class _MenuGridCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuGridCard({required this.item});

  static const double _emojiSize = 24;
  static const double _iconSize = 28;

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled && item.onTap != null;

    final core = CustomCard(
      onTap: enabled ? item.onTap : null,
      elevated: enabled,
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: _emojiSize + 4,
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: _emojiSize, height: 1.1),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  item.icon,
                  size: _iconSize,
                  color: AppColors.gridIconTint,
                ),
                const SizedBox(height: 10),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 13,
                    height: 1.2,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (item.showBadge && enabled)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.joinAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );

    if (enabled) return core;

    return Opacity(
      opacity: 0.48,
      child: IgnorePointer(child: core),
    );
  }
}

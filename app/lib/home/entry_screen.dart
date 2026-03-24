import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../checkin/checkin_service.dart';
import '../event_join/event_join_provider.dart';
import '../event_join/event_join_screen.dart';
import '../lista_novios/novios_registry_service.dart';
import '../solteros/solteros_service.dart';
import '../solteros/solteros_provider.dart';
import '../ui/app_theme.dart';
import '../ui/appear_animation.dart';
import '../ui/custom_button.dart';
import '../ui/custom_card.dart';
import '../user_context/user_context_provider.dart';

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
  final NoviosRegistryService _registryService = NoviosRegistryService();
  static const double _autoCheckinRadiusMeters = 250;
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
                    label: 'Activar',
                    icon: Icons.my_location,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _tryAutoCheckin(userContext);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.x1_5),
                Expanded(
                  child: CustomButton(
                    label: 'No activar',
                    onPressed: () => Navigator.of(ctx).pop(),
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
      if (distance > _autoCheckinRadiusMeters) return;

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
                      label: 'Sí',
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1_5),
                  Expanded(
                    child: CustomButton(
                      label: 'No',
                      onPressed: () => Navigator.of(ctx).pop(false),
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
                      label: 'Sí',
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1_5),
                  Expanded(
                    child: CustomButton(
                      label: 'No',
                      onPressed: () => Navigator.of(ctx).pop(false),
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
    final eventId = userContext.eventId ?? '';
    final disableTablesForEvent = eventId.toUpperCase() == 'CAROYNONI';
    _maybeAskName(context, userContext);
    _maybeAskSingle(context, userContext);
    _maybeAskLocation(context, userContext);

    if (!hasEvent) {
      return Scaffold(
        backgroundColor: AppColors.background,
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
                        constraints: const BoxConstraints(maxWidth: 440),
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
        onTap: disableTablesForEvent ? null : () => context.push('/mesas'),
        enabled: !disableTablesForEvent,
      ),
      _MenuItem(
        emoji: '🎁',
        icon: Icons.card_giftcard_outlined,
        label: 'Lista de novios',
        onTap: () => context.push('/lista_novios'),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasEvent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(AppSpacing.x2, 28, AppSpacing.x2, 22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentHeaderStart,
                      AppColors.accentHeaderEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
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
                    const SizedBox(height: 8),
                    Text(
                      subtitleHeader,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.94),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                color: AppColors.background,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
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
                            final cross = w >= 520 ? 3 : 2;
                            final ratio = w >= 520 ? 1.05 : 1.0;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: menuItems.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cross,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: ratio,
                              ),
                              itemBuilder: (context, i) {
                                final item = menuItems[i];
                                return StaggerAppear(
                                  index: i,
                                  child: _MenuGridCard(item: item),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        const Divider(),
                        const SizedBox(height: AppSpacing.x1),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => _confirmExitEvent(context, userContext),
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text('Salir del evento'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                            ),
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

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled && item.onTap != null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomCard(
          onTap: enabled ? item.onTap : null,
          elevated: enabled,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x1_5, vertical: AppSpacing.x2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: AppSpacing.x1),
              Icon(
                item.icon,
                size: 32,
                color: enabled ? AppColors.gridIconTint : Colors.grey.shade400,
              ),
              const SizedBox(height: AppSpacing.x1_5),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title.copyWith(
                  fontSize: 13.5,
                  color: enabled ? AppColors.textPrimary : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        if (item.showBadge)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

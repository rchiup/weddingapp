import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../solteros/solteros_service.dart';
import '../solteros/solteros_provider.dart';
import '../ui/app_theme.dart';
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
  final SolterosService _solterosService = SolterosService();

  void _maybeAskName(BuildContext context, UserContextProvider userContext) {
    final hasEvent = userContext.eventId != null && userContext.eventId!.isNotEmpty;
    final noName = userContext.userName == null || userContext.userName!.trim().isEmpty;
    if (!hasEvent || !noName || _nameDialogShown) return;
    _nameDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      _showNameDialog(context, userContext);
    });
  }

  void _maybeAskSingle(BuildContext context, UserContextProvider userContext) {
    final hasEvent = userContext.eventId != null && userContext.eventId!.isNotEmpty;
    final hasName = userContext.userName != null && userContext.userName!.trim().isNotEmpty;
    if (!hasEvent || !hasName) return;
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
            content: const Text('Puedes activar el modo soltero para usar el chat y la lista.'),
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
      return;
    }

    // Activar directamente modo soltero cuando responde que sí.
    final userId = userContext.userId ?? '';
    final name = (userContext.userName ?? '').trim();
    if (userId.isEmpty || name.isEmpty) return;
    try {
      await _solterosService.activateSingle(eventId: eventId, userId: userId, name: name);
      await userContext.activateSingleForEvent(eventId);
    } catch (_) {
      // Para demo mantenemos el error silencioso; la UX principal es la respuesta Sí/No.
    }
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final hasEvent = userContext.eventId != null && userContext.eventId!.isNotEmpty;
    final eventId = userContext.eventId ?? '';
    final disableTablesForEvent = eventId.toUpperCase() == 'CAROYNONI';
    _maybeAskName(context, userContext);
    _maybeAskSingle(context, userContext);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: ListView(
          children: [
            if (hasEvent) ...[
              CustomCard(
                padding: const EdgeInsets.all(AppSpacing.x2),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.event_available, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.x1_5),
                    Expanded(
                      child: Text(
                        userContext.eventName ?? 'Evento activo',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
            _EntryCard(
              title: 'Unirme a un evento',
              subtitle: 'Ingresa un código o escanea un QR',
              icon: Icons.qr_code_2,
              onTap: () => context.go('/event_join'),
            ),
            if (hasEvent) ...[
              const SizedBox(height: AppSpacing.x2),
              _EntryCard(
                title: '📸 Fotos del evento',
                subtitle: 'Ver y subir fotos del evento',
                icon: Icons.photo_library_outlined,
                onTap: () => context.go('/fotos'),
                enabled: true,
              ),
              const SizedBox(height: AppSpacing.x2),
              _EntryCard(
                title: '🎉 Ver quién llegó',
                subtitle: 'Entra para ver quién ya llegó',
                icon: Icons.celebration_outlined,
                onTap: () => context.go('/checkin'),
                enabled: true,
              ),
              if (userContext.isSingleForCurrentEvent) ...[
                const SizedBox(height: AppSpacing.x2),
                Consumer<SolterosProvider>(
                  builder: (context, solteros, _) {
                    final hasUnread = solteros.hasAnyUnread;
                    return _EntryCard(
                      title: hasUnread ? '💘 Solteros (nuevo)' : '💘 Solteros',
                      subtitle: 'Chat y lista de solteros del evento',
                      icon: Icons.favorite_border,
                      onTap: () => context.go('/solteros'),
                      enabled: true,
                    );
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.x2),
              _EntryCard(
                title: '👥 Invitados',
                subtitle: disableTablesForEvent
                    ? 'No aplica para este evento'
                    : 'Buscar mesa e invitados',
                icon: Icons.people_outline,
                onTap: () => context.go('/mesas'),
                enabled: !disableTablesForEvent,
              ),
              const SizedBox(height: AppSpacing.x2),
              _EntryCard(
                title: '🎁 Lista de novios',
                subtitle: 'Ver lista de regalos',
                icon: Icons.card_giftcard_outlined,
                onTap: () => context.go('/lista_novios'),
                enabled: true,
              ),
              if (userContext.isAdmin) ...[
                const SizedBox(height: AppSpacing.x2),
                _EntryCard(
                  title: '👰🤵 Panel de novios',
                  subtitle: 'Editar link de la lista',
                  icon: Icons.admin_panel_settings_outlined,
                  onTap: () => context.go('/novios_admin'),
                  enabled: true,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _EntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled ? AppColors.primary.withOpacity(0.10) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: enabled ? AppColors.primary : Colors.grey),
          ),
          const SizedBox(width: AppSpacing.x1_5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  subtitle,
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: enabled ? AppColors.textPrimary.withOpacity(0.35) : Colors.grey),
        ],
      ),
    );
  }
}

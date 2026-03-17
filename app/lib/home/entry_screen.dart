import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../solteros/solteros_service.dart';
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
    final controller = TextEditingController();
    String? errorText;
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> submit() async {
            final name = controller.text.trim();
            if (name.isEmpty) {
              setState(() => errorText = 'El nombre es obligatorio');
              return;
            }
            await userContext.setUserName(name);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (context.mounted) _maybeAskSingle(context, userContext);
          }

          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('¿Cómo te llamas?'),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Tu nombre',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
                onChanged: (_) {
                  if (errorText != null) setState(() => errorText = null);
                },
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
            content: const Text('Responde para habilitar funciones del módulo de solteros.'),
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
      return;
    }

    await _showSingleConfirmDialog(context, userContext);
  }

  Future<void> _showSingleConfirmDialog(
    BuildContext context,
    UserContextProvider userContext,
  ) async {
    final eventId = userContext.eventId ?? '';
    final userId = userContext.userId ?? '';
    final name = (userContext.userName ?? '').trim();
    if (eventId.trim().isEmpty || userId.trim().isEmpty || name.isEmpty) return;

    bool accepted = false;
    bool loading = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> activate() async {
            if (!accepted || loading) return;
            setState(() {
              loading = true;
              error = null;
            });
            try {
              await _solterosService.activateSingle(eventId: eventId, userId: userId, name: name);
              await userContext.activateSingleForEvent(eventId);
              if (ctx.mounted) Navigator.of(ctx).pop();
            } catch (e) {
              setState(() => error = '$e');
            } finally {
              if (ctx.mounted) setState(() => loading = false);
            }
          }

          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Modo soltero (irreversible)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Si lo activas, aparecerás en la lista de solteros del evento y no podrás desactivarlo después.',
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: accepted,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Entiendo y quiero activar modo soltero'),
                    onChanged: loading ? null : (v) => setState(() => accepted = v ?? false),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: loading ? 'Activando...' : 'Activar',
                    onPressed: (!accepted || loading) ? null : activate,
                    loading: loading,
                    icon: Icons.favorite,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
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
                _EntryCard(
                  title: '💘 Solteros',
                  subtitle: 'Chat y lista de solteros del evento',
                  icon: Icons.favorite_border,
                  onTap: () => context.go('/solteros'),
                  enabled: true,
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

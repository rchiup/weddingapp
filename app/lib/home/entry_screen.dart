import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  Future<void> _showNameDialog(BuildContext context, UserContextProvider userContext) async {
    final controller = TextEditingController();
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('¿Cómo te llamas?'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Tu nombre',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Más tarde'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  userContext.setUserName(name);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final hasEvent = userContext.eventId != null && userContext.eventId!.isNotEmpty;
    _maybeAskName(context, userContext);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido al evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (hasEvent) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available, color: Colors.pink),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userContext.eventName ?? 'Evento activo',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _EntryCard(
              title: 'Unirme a un evento',
              subtitle: 'Ingresa un código o escanea un QR',
              icon: Icons.qr_code_2,
              onTap: () => context.go('/event_join'),
            ),
            if (hasEvent) ...[
              const SizedBox(height: 16),
              _EntryCard(
                title: '📸 Fotos del evento',
                subtitle: 'Ver y subir fotos del evento',
                icon: Icons.photo_library_outlined,
                onTap: () => context.go('/fotos'),
                enabled: true,
              ),
              const SizedBox(height: 16),
              _EntryCard(
                title: '🎉 Ya llegué',
                subtitle: 'Hacer check-in al evento',
                icon: Icons.celebration_outlined,
                onTap: () => context.go('/checkin'),
                enabled: true,
              ),
              const SizedBox(height: 16),
              _EntryCard(
                title: '👥 Invitados',
                subtitle: 'Buscar mesa e invitados',
                icon: Icons.people_outline,
                onTap: () => context.go('/mesas'),
                enabled: true,
              ),
              const SizedBox(height: 16),
              _EntryCard(
                title: '🎁 Lista de novios',
                subtitle: 'Ver lista de regalos',
                icon: Icons.card_giftcard_outlined,
                onTap: () => context.go('/lista_novios'),
                enabled: true,
              ),
              if (userContext.isAdmin) ...[
                const SizedBox(height: 16),
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
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
          color: enabled ? null : Colors.grey.shade100,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: enabled ? Colors.pink.shade50 : Colors.grey.shade300,
              child: Icon(icon, color: enabled ? Colors.pink.shade400 : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: enabled ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: enabled ? Colors.grey.shade700 : Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: enabled ? null : Colors.grey),
          ],
        ),
      ),
    );
  }
}

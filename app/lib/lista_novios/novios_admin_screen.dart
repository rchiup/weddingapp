import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'novios_registry_service.dart';

class NoviosAdminScreen extends StatefulWidget {
  const NoviosAdminScreen({super.key});

  @override
  State<NoviosAdminScreen> createState() => _NoviosAdminScreenState();
}

class _NoviosAdminScreenState extends State<NoviosAdminScreen> {
  final _urlController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = context.read<UserContextProvider>();
      if (ctx.isAdmin) {
        _loadCurrentUrl();
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (eventId.isEmpty) ...[
              const Text('Debes unirte a un evento primero.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/entry'),
                child: const Text('Volver'),
              ),
            ] else ...[
              if (!isAdmin) ...[
                const Text(
                  'Este panel solo está disponible si te unes con el código de novios.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: usa "$eventId-NOVIOS" al unirte al evento.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ] else ...[
                const SizedBox(height: 4),
                const Text(
                  'Pega el link de la lista de regalos (Falabella/Paris/Ripley o cualquier URL).',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Link lista de novios',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _saveUrl(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _saveUrl,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_loading ? 'Guardando...' : 'Guardar'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}


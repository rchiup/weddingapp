import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'mesas_detail_screen.dart';
import 'mesas_provider.dart';
import 'mesas_validator.dart';

/// Pantalla de búsqueda de mesas
class MesasSearchScreen extends StatefulWidget {
  const MesasSearchScreen({super.key});

  @override
  State<MesasSearchScreen> createState() => _MesasSearchScreenState();
}

class _MesasSearchScreenState extends State<MesasSearchScreen> {
  final _nameController = TextEditingController();
  final _tableController = TextEditingController();
  final _nameFormKey = GlobalKey<FormState>();
  final _tableFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final provider = context.watch<MesasProvider>();
    final eventId = userContext.eventId ?? '';
    final guestsVisible = userContext.settings.guestsVisible;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Buscar mi mesa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Form(
            key: _tableFormKey,
            child: TextFormField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Número de mesa',
                border: OutlineInputBorder(),
              ),
              validator: MesasValidator.validateTableNumber,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (!_tableFormKey.currentState!.validate()) return;
                    final table = await provider.findTableByNumber(
                      eventId,
                      _tableController.text.trim(),
                    );
                    if (!mounted) return;
                    if (table == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mesa no encontrada')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MesasDetailScreen(table: table),
                      ),
                    );
                  },
            child: const Text('Buscar por número'),
          ),
          const SizedBox(height: 16),
          Form(
            key: _nameFormKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre y apellido',
                border: OutlineInputBorder(),
              ),
              validator: MesasValidator.validateName,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (!_nameFormKey.currentState!.validate()) return;
                    if (!guestsVisible) {
                      final table = await provider.findTableByGuestNameExact(
                        eventId,
                        _nameController.text.trim(),
                      );
                      if (!mounted) return;
                      if (table == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Invitado no encontrado')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MesasDetailScreen(table: table),
                        ),
                      );
                      return;
                    }

                    await provider.searchGuests(
                      eventId,
                      _nameController.text.trim(),
                    );
                  },
            child: Text(guestsVisible ? 'Buscar por nombre' : 'Buscar mi mesa'),
          ),
          const SizedBox(height: 12),
          if (guestsVisible) ...[
            const Text(
              'Resultados',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: provider.guestResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final guest = provider.guestResults[index];
                  return ListTile(
                    title: Text(guest.name),
                    subtitle: Text('Mesa ${guest.tableNumber}'),
                    onTap: () async {
                      final table = await provider.findTableByNumber(
                        eventId,
                        guest.tableNumber,
                      );
                      if (!mounted || table == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MesasDetailScreen(table: table),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

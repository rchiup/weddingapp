import 'package:flutter/material.dart';

import 'mesa_model.dart';

/// Pantalla de detalle de mesa
class MesasDetailScreen extends StatelessWidget {
  final MesaModel table;

  const MesasDetailScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa ${table.number}'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: table.guests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final guest = table.guests[index];
          return ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(guest.name),
          );
        },
      ),
    );
  }
}

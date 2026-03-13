import 'package:flutter/material.dart';

/// Pantalla principal del flujo de solteros
///
/// Muestra listado de solteros (mock), botones de like y pass,
/// y un indicador de match. No contiene lógica real.
class SolterosScreen extends StatelessWidget {
  const SolterosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockProfiles = List.generate(8, (index) => 'Invitado #${index + 1}');
    const hasMatch = true;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (hasMatch)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.favorite, color: Colors.pink),
                  SizedBox(width: 8),
                  Text('Tienes un match'),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: mockProfiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(mockProfiles[index]),
                  subtitle: const Text('Perfil anónimo'),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Pasar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Like'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

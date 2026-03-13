import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home de solteros (MVP visual)
///
/// Muestra perfiles anónimos mock, botones de like y siguiente,
/// y un indicador de match fijo para visualizar el flujo.
class SinglesHome extends StatelessWidget {
  const SinglesHome({super.key});

  @override
  Widget build(BuildContext context) {
    final mockProfiles = List.generate(6, (index) => 'Invitado #${index + 1}');
    const hasMatch = true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar'),
        actions: [
          IconButton(
            onPressed: () => context.go('/chat'),
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
          ),
          IconButton(
            onPressed: () => context.go('/gallery'),
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Galería',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasMatch)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tienes un match',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
                    child: const Text('Siguiente'),
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
      ),
    );
  }
}

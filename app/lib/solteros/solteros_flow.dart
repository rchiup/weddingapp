import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'solteros_screen.dart';

/// Entry point del flujo de solteros
///
/// Maneja navegación interna del flujo (listado y chat),
/// sin depender de módulos de fotos.
class SolterosFlow extends StatefulWidget {
  const SolterosFlow({super.key});

  @override
  State<SolterosFlow> createState() => _SolterosFlowState();
}

class _SolterosFlowState extends State<SolterosFlow> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SolterosScreen(),
      const _SolterosChatMockScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solteros'),
        leading: IconButton(
          onPressed: () => context.go('/entry'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Solteros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

class _SolterosChatMockScreen extends StatelessWidget {
  const _SolterosChatMockScreen();

  @override
  Widget build(BuildContext context) {
    final mockMessages = [
      'Hola! ¿Cómo estás?',
      '¿En qué mesa estás?',
      '¡Nos vemos en la pista!',
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mockMessages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Align(
          alignment: index.isEven ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: index.isEven ? Colors.pink.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(mockMessages[index]),
          ),
        );
      },
    );
  }
}

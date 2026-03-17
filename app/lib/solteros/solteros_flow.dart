import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'solteros_screen.dart';
import 'solteros_chat_screen.dart';

/// Entry point del flujo de solteros
///
/// Maneja navegación interna del flujo (listado y chat),
/// sin depender de módulos de fotos.
class SolterosFlow extends StatefulWidget {
  final int initialIndex;

  const SolterosFlow({super.key, this.initialIndex = 0});

  @override
  State<SolterosFlow> createState() => _SolterosFlowState();
}

class _SolterosFlowState extends State<SolterosFlow> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SolterosScreen(),
      const SolterosChatScreen(),
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

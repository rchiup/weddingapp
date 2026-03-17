import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import 'solteros_provider.dart';
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
    final solterosState = context.watch<SolterosProvider>();
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.people_outline,
              color: solterosState.hasUnreadDm ? AppColors.primary : null,
            ),
            label: 'Solteros',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (solterosState.hasUnreadGlobal)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

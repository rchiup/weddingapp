import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'event_join_provider.dart';
import 'event_join_screen.dart';

/// Entry point del flujo Event Join
class EventJoinFlow extends StatelessWidget {
  const EventJoinFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventJoinProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Unirme a un evento'),
          leading: IconButton(
            onPressed: () => context.go('/entry'),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          ),
        ),
        body: const EventJoinScreen(),
      ),
    );
  }
}

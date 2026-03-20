import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mesas_provider.dart';
import 'mesas_search_screen.dart';
import '../utils/nav_safe.dart';
import '../utils/nested_flow_navigator.dart';

/// Entry point del flujo de Mesas
class MesasFlow extends StatelessWidget {
  const MesasFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MesasProvider(),
      child: NestedFlowNavigator(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Mesas'),
            leading: IconButton(
              onPressed: () => popOrEntry(context),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
            ),
          ),
          body: const MesasSearchScreen(),
        ),
      ),
    );
  }
}

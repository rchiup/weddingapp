import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../utils/nav_safe.dart';
import '../utils/nested_flow_navigator.dart';
import 'mesas_provider.dart';
import 'mesas_search_screen.dart';

/// Entry point del flujo de Mesas
class MesasFlow extends StatelessWidget {
  const MesasFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MesasProvider(),
      child: NestedFlowNavigator(
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Invitados', style: AppTextStyles.title.copyWith(fontSize: 18)),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/startup_background.dart';
import '../utils/nav_safe.dart';
import '../utils/nested_flow_navigator.dart';
import 'event_join_provider.dart';
import 'event_join_screen.dart';

/// Entry point del flujo Event Join
class EventJoinFlow extends StatelessWidget {
  const EventJoinFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventJoinProvider(),
      child: NestedFlowNavigator(
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Unirme a un evento', style: AppTextStyles.title.copyWith(fontSize: 18)),
            backgroundColor: AppColors.background,
            leading: IconButton(
              onPressed: () => popOrEntry(context),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
            ),
          ),
          body: const StartupBackground(
            child: SafeArea(child: EventJoinScreen()),
          ),
        ),
      ),
    );
  }
}

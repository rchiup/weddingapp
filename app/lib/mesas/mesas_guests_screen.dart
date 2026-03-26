import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../user_context/user_context_provider.dart';
import 'mesas_organize_tab.dart';
import 'mesas_search_screen.dart';

/// Invitados: búsqueda para todos; pestaña Organizar solo para novios (admin).
class MesasGuestsScreen extends StatelessWidget {
  const MesasGuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<UserContextProvider>().isAdmin;
    if (!admin) {
      return const MesasSearchScreen();
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: AppColors.background,
            child: TabBar(
              labelColor: AppColors.primaryDark,
              unselectedLabelColor: AppColors.textPrimary.withOpacity(0.6),
              tabs: const [
                Tab(text: 'Buscar'),
                Tab(text: 'Organizar'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                MesasSearchScreen(),
                MesasOrganizeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

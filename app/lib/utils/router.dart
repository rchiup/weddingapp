import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../checkin/checkin_screen.dart';
import '../event_join/event_join_flow.dart';
import '../home/blocked_screen.dart';
import '../home/entry_screen.dart';
import '../fotos/fotos_flow.dart';
import '../admin_export/admin_export_flow.dart';
import '../como_llegar/como_llegar_screen.dart';
import '../mesas/mesas_flow.dart';
import '../lista_novios/lista_novios_screen.dart';
import '../lista_novios/novios_admin_screen.dart';
import '../rsvp/rsvp_flow.dart';
import '../solteros/solteros_flow.dart';
import '../solteros/solteros_dm_screen.dart';
import '../ui/app_theme.dart';
import '../user_context/user_context_provider.dart';
import 'nav_safe.dart';
import 'nested_flow_navigator.dart';

/// Configuración de rutas de la aplicación
/// 
/// Define todas las rutas navegables usando go_router
/// para una navegación declarativa y type-safe
class AppRouter {
  static GoRouter createRouter(UserContextProvider userContext) {
    return GoRouter(
      initialLocation: '/entry',
      refreshListenable: userContext,
      redirect: (context, state) {
        final loc = state.uri.path;
        if (loc.startsWith('/solteros')) {
          if (!userContext.isSingleForCurrentEvent) {
            return '/entry';
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/entry',
          name: 'entry',
          builder: (context, state) => const EntryScreen(),
        ),
        GoRoute(
          path: '/event_join',
          name: 'event_join',
          builder: (context, state) => const EventJoinFlow(),
        ),
        GoRoute(
          path: '/blocked',
          name: 'blocked',
          builder: (context, state) =>
              BlockedScreen(reason: state.uri.queryParameters['reason']),
        ),
        GoRoute(
          path: '/solteros',
          name: 'solteros',
          builder: (context, state) => const SolterosFlow(initialIndex: 0),
        ),
        GoRoute(
          path: '/solteros/chats',
          name: 'solteros_chats',
          builder: (context, state) => const SolterosFlow(initialIndex: 1),
        ),
        GoRoute(
          path: '/solteros/chat',
          name: 'solteros_chat',
          builder: (context, state) => const SolterosFlow(initialIndex: 2),
        ),
        GoRoute(
          path: '/solteros/dm/:otherUserId',
          name: 'solteros_dm',
          builder: (context, state) => SolterosDmScreen(
            otherUserId: state.pathParameters['otherUserId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/fotos',
          name: 'fotos',
          builder: (context, state) => const FotosFlow(),
        ),
        GoRoute(
          path: '/como_llegar',
          name: 'como_llegar',
          builder: (context, state) => const ComoLlegarScreen(),
        ),
        GoRoute(
          path: '/rsvp',
          name: 'rsvp',
          builder: (context, state) => const RsvpFlow(),
        ),
        GoRoute(
          path: '/mesas',
          name: 'mesas',
          builder: (context, state) => const MesasFlow(),
        ),
        GoRoute(
          path: '/admin_export',
          name: 'admin_export',
          builder: (context, state) => const AdminExportFlow(),
        ),
        GoRoute(
          path: '/lista_novios',
          name: 'lista_novios',
          builder: (context, state) => const ListaNoviosScreen(),
        ),
        GoRoute(
          path: '/novios_admin',
          name: 'novios_admin',
          builder: (context, state) => const NoviosAdminScreen(),
        ),
        GoRoute(
          path: '/checkin',
          name: 'checkin',
          builder: (context, state) => NestedFlowNavigator(
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  '🎉 ¿Quién llegó?',
                  style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
                ),
                backgroundColor: AppColors.background,
                leading: IconButton(
                  onPressed: () => popOrEntry(context),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver',
                ),
              ),
              body: const CheckinScreen(),
            ),
          ),
        ),
        // Más rutas se agregarán aquí según se desarrollen los módulos
      ],
    );
  }
}

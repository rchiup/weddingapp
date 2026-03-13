import 'package:go_router/go_router.dart';

import '../checkin/checkin_screen.dart';
import '../event_join/event_join_flow.dart';
import '../home/blocked_screen.dart';
import '../home/entry_screen.dart';
import '../fotos/fotos_flow.dart';
import '../admin_export/admin_export_flow.dart';
import '../mesas/mesas_flow.dart';
import '../lista_novios/lista_novios_screen.dart';
import '../rsvp/rsvp_flow.dart';
import '../solteros/solteros_flow.dart';
import '../user_context/user_context_provider.dart';

/// Configuración de rutas de la aplicación
/// 
/// Define todas las rutas navegables usando go_router
/// para una navegación declarativa y type-safe
class AppRouter {
  static GoRouter createRouter(UserContextProvider userContext) {
    return GoRouter(
      initialLocation: '/entry',
      refreshListenable: userContext,
      redirect: (context, state) => null,
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
          builder: (context, state) => const SolterosFlow(),
        ),
        GoRoute(
          path: '/fotos',
          name: 'fotos',
          builder: (context, state) => const FotosFlow(),
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
          path: '/checkin',
          name: 'checkin',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: const Text('Ya llegué'),
              leading: IconButton(
                onPressed: () => context.go('/entry'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Volver',
              ),
            ),
            body: const CheckinScreen(),
          ),
        ),
        // Más rutas se agregarán aquí según se desarrollen los módulos
      ],
    );
  }
}

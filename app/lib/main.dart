import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'solteros/solteros_provider.dart';
import 'ui/app_theme.dart';
import 'user_context/user_context_provider.dart';
import 'utils/router.dart';

/// Punto de entrada principal de la aplicación
///
/// Inicializa Firebase y configura los providers globales
/// para gestión de estado (autenticación, eventos, etc.)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initializeDateFormatting('es');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Evitar error "client is offline" en web: forzar red y sin persistencia
  final firestore = FirebaseFirestore.instance;
  if (kIsWeb) {
    firestore.settings = const Settings(
      persistenceEnabled: false,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  await firestore.enableNetwork();

  final userContext = UserContextProvider();
  await userContext.initialize();

  runApp(WeddingApp(userContext: userContext));
}

class WeddingApp extends StatelessWidget {
  final UserContextProvider userContext;

  const WeddingApp({super.key, required this.userContext});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userContext),
        ChangeNotifierProxyProvider<UserContextProvider, SolterosProvider>(
          create: (_) => SolterosProvider(),
          update: (_, userContext, solteros) {
            final provider = solteros ?? SolterosProvider();
            provider.updateContext(userContext);
            return provider;
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Wedding App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: AppRouter.createRouter(userContext),
      ),
    );
  }
}

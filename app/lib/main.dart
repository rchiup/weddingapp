import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'user_context/user_context_provider.dart';
import 'utils/qa_config.dart';
import 'utils/router.dart';

/// Punto de entrada principal de la aplicación
/// 
/// Inicializa Firebase y configura los providers globales
/// para gestión de estado (autenticación, eventos, etc.)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        // Aquí se agregarán más providers según se necesiten
        // ChangeNotifierProvider(create: (_) => EventProvider()),
        // ChangeNotifierProvider(create: (_) => MatchProvider()),
      ],
      child: MaterialApp.router(
        title: 'Wedding App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.pink,
          useMaterial3: true,
        ),
        routerConfig: AppRouter.createRouter(userContext),
      ),
    );
  }
}

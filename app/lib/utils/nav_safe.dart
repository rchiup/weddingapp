import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Vuelve a la pantalla anterior en la pila de [GoRouter].
///
/// Si se entró por enlace directo y no hay historial, va al menú principal.
/// Usar en botones "atrás" en lugar de [GoRouter.go] a `/entry`, para que el
/// gesto de sistema / botón atrás del navegador no salte "de más" ni se sienta
/// como doble animación.
void popOrEntry(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/entry');
  }
}

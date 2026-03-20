import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'nested_flow_navigator.dart';

/// Vuelve a la pantalla anterior en la pila de [GoRouter].
///
/// Si se entró por enlace directo y no hay historial, va al menú principal.
/// Usar en botones "atrás" en lugar de [GoRouter.go] a `/entry`, para que el
/// gesto de sistema / botón atrás del navegador no salte "de más" ni se sienta
/// como doble animación.
///
/// Si el flujo está envuelto en [NestedFlowNavigator], primero hace pop de las
/// rutas imperativas (`Navigator.push` dentro del flujo) y solo después pop de
/// GoRouter — evita volver al menú principal al cerrar una foto o detalle.
void popOrEntry(BuildContext context) {
  final nestedKey = NestedFlowNavigator.maybeNavigatorKeyOf(context);
  final nested = nestedKey?.currentState;
  if (nested != null && nested.canPop()) {
    nested.pop();
    return;
  }
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/entry');
  }
}

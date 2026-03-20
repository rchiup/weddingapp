import 'package:flutter/material.dart';

/// Scope que expone el [Navigator] interno de un flujo (galería, mesas, etc.).
class _NestedFlowNavScope extends InheritedWidget {
  const _NestedFlowNavScope({
    required super.child,
    required this.navigatorKey,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  bool updateShouldNotify(_NestedFlowNavScope oldWidget) =>
      navigatorKey != oldWidget.navigatorKey;
}

/// Envuelve la raíz de un flujo accedido vía [GoRouter] (`context.push`).
///
/// Los `Navigator.of(context).push` del flujo apilan rutas **solo aquí dentro**.
/// Así el gesto atrás / swipe iOS y el botón atrás del sistema hacen primero
/// pop de la pantalla interna (ej. foto a pantalla completa) y **no** saltan
/// directo al menú principal ni disparan doble animación con GoRouter.
class NestedFlowNavigator extends StatefulWidget {
  const NestedFlowNavigator({super.key, required this.child});

  final Widget child;

  /// Para [popOrEntry]: intentar pop en este navigator antes que en GoRouter.
  ///
  /// Usa [getInheritedWidgetOfExactType] (no depende del build) para poder
  /// llamarse desde callbacks como `onPressed`.
  static GlobalKey<NavigatorState>? maybeNavigatorKeyOf(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_NestedFlowNavScope>();
    return scope?.navigatorKey;
  }

  @override
  State<NestedFlowNavigator> createState() => _NestedFlowNavigatorState();
}

class _NestedFlowNavigatorState extends State<NestedFlowNavigator> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return _NestedFlowNavScope(
      navigatorKey: _navKey,
      child: Navigator(
        key: _navKey,
        onGenerateInitialRoutes: (NavigatorState nav, String initialRoute) {
          return [
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: '_flowRoot'),
              builder: (_) => widget.child,
            ),
          ];
        },
      ),
    );
  }
}

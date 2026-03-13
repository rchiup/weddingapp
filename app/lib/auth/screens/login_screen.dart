import 'package:flutter/material.dart';

/// Pantalla de inicio de sesión
/// 
/// Permite a los usuarios autenticarse con email/contraseña
/// o mediante otros métodos (Google, Apple, etc.)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TODO: Implementar campos de email y contraseña
              // TODO: Implementar botón de login
              // TODO: Agregar opciones de registro y recuperación de contraseña
              const Text('Pantalla de Login - Por implementar'),
            ],
          ),
        ),
      ),
    );
  }
}

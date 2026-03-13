import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de inicio de sesión (MVP visual)
///
/// UI básica para capturar nombre, mesa y estado de soltero.
/// No contiene lógica real, solo navegación al flujo del MVP.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _tableController = TextEditingController();
  bool _isSingle = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Mesa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isSingle,
                  onChanged: (value) {
                    setState(() {
                      _isSingle = value ?? false;
                    });
                  },
                ),
                const Text('Soy soltero'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go('/singles');
              },
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin_export_screen.dart';

/// Entry point del flujo de export admin
class AdminExportFlow extends StatelessWidget {
  const AdminExportFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar (admin)'),
        leading: IconButton(
          onPressed: () => context.go('/entry'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
        ),
      ),
      body: const AdminExportScreen(),
    );
  }
}

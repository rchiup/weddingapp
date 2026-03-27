import 'package:flutter/material.dart';

import 'mesas_search_screen.dart';

/// Invitados: solo búsqueda de mesa para todos.
/// Organizar mesas / Excel está solo en el panel de novios.
class MesasGuestsScreen extends StatelessWidget {
  const MesasGuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MesasSearchScreen();
  }
}

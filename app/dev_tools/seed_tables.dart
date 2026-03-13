import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../lib/firebase_options.dart';

/// Seed de mesas demo
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  const eventId = 'demo_event';

  final tables = {
    '1': ['Ana Torres', 'Luis Pérez', 'Sofía Vega'],
    '2': ['Carlos Ruiz', 'María López', 'Pedro Díaz'],
    '3': ['Camila Soto', 'Javier Mena', 'Fernanda Ríos'],
  };

  for (final entry in tables.entries) {
    final number = entry.key;
    final guests = entry.value;
    await db
        .collection('events')
        .doc(eventId)
        .collection('tables')
        .doc(number)
        .set({
      'number': number,
      'guests': guests,
    });
  }
}

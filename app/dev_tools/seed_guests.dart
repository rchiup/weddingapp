import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../lib/firebase_options.dart';

/// Seed de invitados demo
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  const eventId = 'demo_event';

  final guests = [
    {'name': 'Ana Torres', 'tableNumber': '1', 'status': 'confirmed', 'isSingle': true},
    {'name': 'Luis Pérez', 'tableNumber': '1', 'status': 'confirmed', 'isSingle': false},
    {'name': 'Sofía Vega', 'tableNumber': '1', 'status': 'invited', 'isSingle': true},
    {'name': 'Carlos Ruiz', 'tableNumber': '2', 'status': 'confirmed', 'isSingle': false},
    {'name': 'María López', 'tableNumber': '2', 'status': 'invited', 'isSingle': false},
    {'name': 'Pedro Díaz', 'tableNumber': '2', 'status': 'confirmed', 'isSingle': false},
    {'name': 'Camila Soto', 'tableNumber': '3', 'status': 'invited', 'isSingle': false},
    {'name': 'Javier Mena', 'tableNumber': '3', 'status': 'confirmed', 'isSingle': false},
    {'name': 'Fernanda Ríos', 'tableNumber': '3', 'status': 'invited', 'isSingle': false},
  ];

  for (final guest in guests) {
    final name = guest['name'] as String;
    await db
        .collection('events')
        .doc(eventId)
        .collection('guests')
        .add({
      ...guest,
      'nameLower': name.toLowerCase(),
    });
  }
}

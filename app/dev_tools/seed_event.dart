import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../lib/firebase_options.dart';

/// Seed de evento DEMO123
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  const eventId = 'demo_event';
  const code = 'DEMO123';

  await db.collection('events').doc(eventId).set({
    'name': 'Boda Demo',
    'date': DateTime.now().toIso8601String(),
    'active': true,
    'settings': {
      'guestsVisible': false,
      'tablesVisible': true,
      'singlesEnabled': false,
      'photosEnabled': true,
      'giftRegistryEnabled': true,
      'giftRegistryProvider': 'falabella',
      'giftRegistryCode': 'DEMO999',
      'giftRegistryUrlOverride': '',
      'adminExportEnabled': true,
    },
  });

  await db.collection('events_by_code').doc(code).set({
    'eventId': eventId,
  });
}

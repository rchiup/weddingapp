import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../lib/firebase_options.dart';

/// Seed de settings del evento demo
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  const eventId = 'demo_event';

  await db.collection('events').doc(eventId).set({
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
  }, SetOptions(merge: true));
}

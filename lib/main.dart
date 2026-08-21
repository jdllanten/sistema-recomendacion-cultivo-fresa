import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'core/constantes/cajas_hive.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox(CajasHive.lecturasHistorial);

  runApp(const ProviderScope(child: FresaApp()));
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:solimage/utils/firebase.dart';
import 'package:solimage/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebaseInit();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(ProviderScope(child: SolimageApp()));
}

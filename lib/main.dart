import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';
import 'package:logbook_app_001/features/logbook/models/user_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    print('═══════════════════════════════════');
    print('FLUTTER ERROR: ${details.exception}');
    print('STACK: ${details.stack}');
    print('═══════════════════════════════════');
  };

  runZonedGuarded(() async {
    await dotenv.load(fileName: ".env");
    await Hive.initFlutter();
    await Hive.openBox('offline_logs');
    await Hive.openBox('pending_queue'); // ← untuk offline queue
    runApp(const MyApp());
  }, (error, stack) {
    print('═══════════════════════════════════');
    print('ZONE ERROR: $error');
    print('STACK: $stack');
    print('═══════════════════════════════════');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const OnboardingView(),
      routes: {
        '/logs': (context) {
          final currentUser =
              ModalRoute.of(context)!.settings.arguments as UserModel;
          return LogView(currentUser: currentUser);
        },
      },
    );
  }
}
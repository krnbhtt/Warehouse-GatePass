import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'src/services/database_service.dart';
import 'src/views/screens/login_screen.dart';
import 'src/views/screens/home_screen.dart';
import 'src/models/user.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database factory for Windows
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  await DatabaseService().initialize();

  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // Optionally, show a dialog or log to a service
  };

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stackTrace) {
      // Optionally, log to a service
      debugPrint('Uncaught error: $error\n$stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karan Infosys - Gate Pass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/home': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User;
          return HomeScreen(user: user);
        },
        // Add other named routes here if needed
      },
    );
  }
}
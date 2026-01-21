import 'package:flutter/material.dart';
import 'package:photo_cleaner/core/di/di.dart';
import 'package:photo_cleaner/features/editor/presentation/editor_screen.dart';
import 'package:photo_cleaner/features/editor/presentation/editor_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
    
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: EditorScreen(),
    );
  }
}



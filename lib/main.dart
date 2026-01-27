import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_cleaner/core/di/di.dart';
import 'package:photo_cleaner/features/editor/presentation/editor_screen.dart';
import 'package:photo_cleaner/features/editor/presentation/editor_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  configureDependencies();
  runApp(EasyLocalization(child: const MyApp(), supportedLocales: [Locale("ru"),Locale("en")],fallbackLocale: Locale("ru"), path: 'assets/translations'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
    
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: EditorScreen(),
    );
  }
}



import 'package:apphud/apphud.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_cleaner/core/di/di.dart';
import 'package:photo_cleaner/features/editor/presentation/editor_screen.dart';
import 'package:photo_cleaner/features/editor/presentation/editor_screen.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initAppsFlyer();
  await initApphud();
  configureDependencies();
  runApp(EasyLocalization(child: const MyApp(), supportedLocales: [Locale("ru"),Locale("en")],fallbackLocale: Locale("ru"), path: 'assets/translations'));
}
Future<void> initApphud() async {
  await Apphud.start(apiKey: "app_Z44sHCCXqhP5FCBDa8SxKBLB7VLpga",);

}
Future<void> initAppsFlyer()async {
  final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "GAgckFyN4yETigBtP4qtRG",
      appId: "6749377146",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
      manualStart: true);
  AppsflyerSdk _appsflyerSdk = AppsflyerSdk(options);


  await _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true);


  _appsflyerSdk.startSDK(
    onSuccess: () {
      print("AppsFlyer SDK initialized successfully.");
    },
    onError: (int errorCode, String errorMessage) {
      print("Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage");
    },
  );
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



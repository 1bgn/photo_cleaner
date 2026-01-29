import 'package:android_id/android_id.dart';
import 'package:apphud/apphud.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:photo_cleaner/core/di/di.dart';
import 'package:photo_cleaner/features/editor/presentation/editor_screen.dart';
import 'package:photo_cleaner/features/editor/presentation/editor_screen.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
  );
  await initAppsFlyer();
  await initApphud();
  await MobileAds.instance.initialize();
  await initAppmetrica();
  configureDependencies();
  const _androidIdPlugin = AndroidId();
  final String? androidId = await _androidIdPlugin.getId();
  print("ANDROIDID $androidId");
  runApp(EasyLocalization(child: const MyApp(), supportedLocales: [Locale("ru"),Locale("en")],fallbackLocale: Locale("ru"), path: 'assets/translations'));
}
Future<void> initApphud() async {
 try{
   // await Apphud.start(apiKey: "app_oJZektLcFSnSRqqmVntw19S16yu29M",);
 }catch(e){
   print(e);
 }

}
Future<void> initAppsFlyer()async {
  final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "zhAZ8YphwvfNovsjD8jttB",
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
Future<void> initAppmetrica() async {
  await AppMetrica.activate(AppMetricaConfig("01fb5cf7-c9be-4e3d-9472-79d889903750"));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [observer],
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



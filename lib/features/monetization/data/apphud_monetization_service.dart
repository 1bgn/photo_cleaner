import 'dart:io';

import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';
import 'package:apphud/models/apphud_models/apphud_composite_model.dart';
import 'package:apphud/models/apphud_models/apphud_debug_level.dart';
import 'package:apphud/models/apphud_models/apphud_error.dart';
import 'package:apphud/models/apphud_models/apphud_paywall.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/composite/apphud_purchase_result.dart';
import 'package:injectable/injectable.dart';

import '../domain/monetization_service.dart';
import 'apphud_listener_bridge.dart';

@LazySingleton(as: MonetizationService)
class ApphudMonetizationService implements MonetizationService {
  static const _apiKey = 'app_Z44sHCCXqhP5FCBDa8SxKBLB7VLpga';

  ApphudListenerBridge? _listener;

  ApphudPaywalls? _paywallsCache;
  List<ApphudPlacement> _placementsCache = const [];

  bool _inited = false;
  bool _syncInProgress = false;

  @override
  Future<void> init() async {
    if (_inited) return;

    // Must be called before SDK initialization. [web:57]
    await Apphud.enableDebugLogs(level: ApphudDebugLevel.high); // [web:57]

    _listener = ApphudListenerBridge(
      onSubscriptionsUpdated: (_) async {
        await sync(force: true);
      },
      onPaywallsLoaded: (pw) => _paywallsCache = pw,
      onPlacementsLoaded: (pl) => _placementsCache = pl,
    );

    await Apphud.setListener(listener: _listener); // [web:57]
    await Apphud.start(apiKey: _apiKey); // [web:57]

    if (Platform.isAndroid) {
      await Apphud.collectDeviceIdentifiers(); // Android only [web:57]
    }

    _inited = true;
  }

  Future<void>? _syncFuture;

  Future<void> sync({bool force = true}) async {
    if (!_inited) await init();

    // если sync уже идёт — просто ждём его
    final inFlight = _syncFuture;
    if (inFlight != null) return inFlight;

    final f = () async {
      final placementsRes = await Apphud.fetchPlacements(forceRefresh: force);
      _placementsCache = placementsRes.placements;

      _paywallsCache = await Apphud.paywallsDidLoadCallback();
    }();

    _syncFuture = f;
    try {
      await f;
    } finally {
      _syncFuture = null;
    }
  }


  @override
  Future<bool> hasPremiumAccess() => Apphud.hasPremiumAccess();

  @override
  Future<bool> hasActiveSubscription() => Apphud.hasActiveSubscription();

  @override
  Future<ApphudPaywall?> getPaywall(String paywallId) async {
    // Чтобы было “актуально”, форсим sync перед чтением.
    await sync(force: true);

    final paywalls = _paywallsCache;
    if (paywalls == null) return null;

    try {
      return paywalls.paywalls.firstWhere((p) => p.identifier == paywallId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ApphudPlacement>> getPlacements({bool forceRefresh = true}) async {
    if (forceRefresh) {
      await sync(force: true);
      return _placementsCache;
    }

    if (_placementsCache.isEmpty) {
      await sync(force: true);
    }
    return _placementsCache;
  }

  @override
  Future<ApphudPurchaseResult> purchase({required ApphudProduct product}) {
    return Apphud.purchase(product: product); // [web:57]
  }

  @override
  Future<ApphudComposite> restorePurchases() => Apphud.restorePurchases(); // [web:57]

  @override
  Future<void> sendAppsFlyerAttribution({
    required Map<String, dynamic> rawData,
    String? appsFlyerId,
  }) async {
    await Apphud.setAttribution(
      provider: ApphudAttributionProvider.appsFlyer,
      data: ApphudAttributionData(rawData: rawData),
      identifier: appsFlyerId,
    ); // [web:57]
  }

  @override
  Future<void> sendFirebaseAttribution({
    required Map<String, dynamic> rawData,
    String? firebaseInstanceId,
  }) async {
    await Apphud.setAttribution(
      provider: ApphudAttributionProvider.firebase,
      data: ApphudAttributionData(rawData: rawData),
      identifier: firebaseInstanceId,
    ); // [web:57]
  }

  @override
  Future<void> sendAppleSearchAdsAttribution() async {
    if (!Platform.isIOS) return;

    // iOS only. Send search ads attribution data to Apphud. [web:57]
    // final ApphudError? err = await Apphud.collectSearchAdsAttribution(); // [web:57]
    // if (err != null) {
    //   // по желанию залогируй err
    // }
  }
}

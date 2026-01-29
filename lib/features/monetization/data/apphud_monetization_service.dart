import 'dart:io';

import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';
import 'package:apphud/models/apphud_models/apphud_composite_model.dart';
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

  @override
  Future<void> init() async {
    if (_inited) return;

    _listener = ApphudListenerBridge(
      onSubscriptionsUpdated: (_) async {
        // можно просто обновлять кэш, но контроллер всё равно может дергать hasPremiumAccess()
      },
      onPaywallsLoaded: (pw) {
        _paywallsCache = pw;
      },
      onPlacementsLoaded: (pl) {
        _placementsCache = pl;
      },
    );

    await Apphud.setListener(listener: _listener);
    await Apphud.start(apiKey: _apiKey);

    if (Platform.isAndroid) {
      await Apphud.collectDeviceIdentifiers();
    }

    // прогрев
    _paywallsCache = await Apphud.paywallsDidLoadCallback();
    _placementsCache = await Apphud.placements();

    _inited = true;
  }

  @override
  Future<bool> hasPremiumAccess() => Apphud.hasPremiumAccess();

  @override
  Future<bool> hasActiveSubscription() => Apphud.hasActiveSubscription();

  @override
  Future<ApphudPaywall?> getPaywall(String paywallId) async {
    final paywalls = _paywallsCache ?? await Apphud.paywallsDidLoadCallback();
    _paywallsCache = paywalls;

    try {
      return paywalls.paywalls.firstWhere((p) => p.identifier == paywallId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ApphudPlacement>> getPlacements({bool forceRefresh = false}) async {
    if (!forceRefresh && _placementsCache.isNotEmpty) return _placementsCache;

    final res = await Apphud.fetchPlacements(forceRefresh: forceRefresh);
    _placementsCache = res.placements;
    return _placementsCache;
  }

  @override
  Future<ApphudPurchaseResult> purchase({required ApphudProduct product}) {
    return Apphud.purchase(product: product);
  }

  @override
  Future<ApphudComposite> restorePurchases() => Apphud.restorePurchases();

  @override
  Future<void> sendAppsFlyerAttribution({
    required Map<String, dynamic> rawData,
    String? appsFlyerId,
  }) {
    return Apphud.setAttribution(
      provider: ApphudAttributionProvider.appsFlyer,
      data: ApphudAttributionData(rawData: rawData),
      identifier: appsFlyerId,
    );
  }

  @override
  Future<void> sendFirebaseAttribution({
    required Map<String, dynamic> rawData,
    String? firebaseInstanceId,
  }) {
    return Apphud.setAttribution(
      provider: ApphudAttributionProvider.firebase,
      data: ApphudAttributionData(rawData: rawData),
      identifier: firebaseInstanceId,
    );
  }

  @override
  Future<void> sendAppleSearchAdsAttribution() async {
    final data = await Apphud.collectSearchAdsAttribution();
    if (data == null) return;

    await Apphud.setAttribution(
      provider: ApphudAttributionProvider.appleAdsAttribution,
      data: ApphudAttributionData(rawData: data),
    );
  }
}

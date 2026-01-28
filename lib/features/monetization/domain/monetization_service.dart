// features/monetization/domain/monetization_service.dart
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_composite_model.dart';
import 'package:apphud/models/apphud_models/apphud_paywall.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/composite/apphud_purchase_result.dart';

abstract class MonetizationService {
  Future<void> init();

  Future<bool> hasPremiumAccess();
  Future<bool> hasActiveSubscription();

  Future<ApphudPaywall?> getPaywall(String paywallId);
  Future<List<ApphudPlacement>> getPlacements({bool forceRefresh = false});

  Future<ApphudPurchaseResult> purchase({
    required ApphudProduct product,
  });

  Future<ApphudComposite> restorePurchases();

  Future<void> sendAppsFlyerAttribution({
    required Map<String, dynamic> rawData,
    String? appsFlyerId,
  });

  Future<void> sendFirebaseAttribution({
    required Map<String, dynamic> rawData,
    String? firebaseInstanceId,
  });

  Future<void> sendAppleSearchAdsAttribution();
}

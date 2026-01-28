import 'package:apphud/models/apphud_models/android/android_purchase_wrapper.dart';
import 'package:apphud/models/apphud_models/apphud_non_renewing_purchase.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_subscription.dart';
import 'package:apphud/models/apphud_models/apphud_user.dart';
import 'package:apphud/models/apphud_models/composite/apphud_product_composite.dart';

import 'package:apphud/apphud.dart' show ApphudListener;

class ApphudListenerAdapter implements ApphudListener {
  @override
  Future<void> apphudDidChangeUserID(String userId) async {}

  @override
  Future<void> apphudDidFecthProducts(List<ApphudProductComposite> products) async {}

  @override
  Future<void> paywallsDidFullyLoad(ApphudPaywalls paywalls) async {}

  @override
  Future<void> userDidLoad(ApphudUser user) async {}

  @override
  Future<void> apphudSubscriptionsUpdated(List<ApphudSubscriptionWrapper> subscriptions) async {}

  @override
  Future<void> apphudNonRenewingPurchasesUpdated(List<ApphudNonRenewingPurchase> purchases) async {}

  @override
  Future<void> placementsDidFullyLoad(List<ApphudPlacement> placements) async {}

  @override
  Future<void> apphudDidReceivePurchase(AndroidPurchaseWrapper purchase) async {}
}

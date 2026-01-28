import 'package:apphud/models/apphud_models/android/android_purchase_wrapper.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_subscription.dart';
import 'package:apphud/models/apphud_models/composite/apphud_product_composite.dart';

import 'apphud_listener_adapter.dart';

class ApphudListenerBridge extends ApphudListenerAdapter {
  ApphudListenerBridge({
    this.onSubscriptionsUpdated,
    this.onPaywallsLoaded,
    this.onPlacementsLoaded,
    this.onProductsFetched,
    this.onAndroidPurchase,
    this.onUserIdChanged,
  });

  final void Function(List<ApphudSubscriptionWrapper> subs)? onSubscriptionsUpdated;
  final void Function(ApphudPaywalls paywalls)? onPaywallsLoaded;
  final void Function(List<ApphudPlacement> placements)? onPlacementsLoaded;
  final void Function(List<ApphudProductComposite> products)? onProductsFetched;
  final void Function(AndroidPurchaseWrapper purchase)? onAndroidPurchase;
  final void Function(String userId)? onUserIdChanged;

  @override
  Future<void> apphudDidChangeUserID(String userId) async {
    onUserIdChanged?.call(userId);
  }

  // Внимание: в твоём интерфейсе метод называется apphudDidFecthProducts (опечатка в SDK)
  @override
  Future<void> apphudDidFecthProducts(List<ApphudProductComposite> products) async {
    onProductsFetched?.call(products);
  }

  @override
  Future<void> paywallsDidFullyLoad(ApphudPaywalls paywalls) async {
    onPaywallsLoaded?.call(paywalls);
  }

  @override
  Future<void> placementsDidFullyLoad(List<ApphudPlacement> placements) async {
    onPlacementsLoaded?.call(placements);
  }

  @override
  Future<void> apphudSubscriptionsUpdated(List<ApphudSubscriptionWrapper> subscriptions) async {
    onSubscriptionsUpdated?.call(subscriptions);
  }

  @override
  Future<void> apphudDidReceivePurchase(AndroidPurchaseWrapper purchase) async {
    onAndroidPurchase?.call(purchase);
  }
}

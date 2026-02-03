// features/monetization/presentation/monetization_controller.dart
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_paywall.dart';
import 'package:injectable/injectable.dart';
import 'package:signals/signals.dart';

import '../data/apphud_monetization_service.dart';
import '../domain/monetization_service.dart';

@injectable
class MonetizationController {
  MonetizationController(this._service);

  final MonetizationService _service;

  final isReady = signal(false);
  final isBusy = signal(false);
  final error = signal<String?>(null);

  final hasPremium = signal<bool>(false);
  final hasSubcription = signal<bool>(false);
  final paywall = signal<ApphudPaywall?>(null);

  Future<void> init() async {
    if (isReady.value) return;

    try {
      isBusy.value = true;
      error.value = null;

      await _service.init();
      await refreshStatus();

      paywall.value = await _service.getPaywall('main_paywall');
      // print("FVREWVDSVsdv ${(await _service.getPlacements()).first}");
      isReady.value = true;
    } catch (e) {
      error.value = '$e';
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> refreshStatus() async {
    final premium = await _service.hasPremiumAccess();
    hasPremium.value = premium;
  }
  Future<bool> hasActiveSubscription() async {
    final sub = await _service.hasActiveSubscription();
    hasSubcription.value = sub;
    return sub;
  }
  Future<void> checkSubscriptionStatus({bool forceSync = true}) async {
    try {
      isBusy.value = true;
      error.value = null;

      await _service.init();

      if (forceSync && _service is ApphudMonetizationService) {
        await (_service as ApphudMonetizationService).sync(force: true);
      }

      hasSubcription.value = await _service.hasActiveSubscription();
      hasPremium.value = await _service.hasPremiumAccess();
    } catch (e) {
      error.value = '$e';
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> buyWeekly() => _buyByProductId('sonicforge_weekly');
  Future<void> buyMonthly() => _buyByProductId('sonicforge_monthly');

  Future<void> _buyByProductId(String id) async {
    final pw = paywall.value;
    if (pw?.products == null) {
      error.value = 'Paywall/products not loaded';
      return;
    }

    final product = pw!.products!.firstWhere(
          (p) => p.productId == id,
      orElse: () => throw StateError('Product $id not found in paywall'),
    );

    try {
      isBusy.value = true;
      error.value = null;
      final result = await _service.purchase(product: product);
      print("VDSVSDVsdvsd ${result}");

      if (result.error != null) {
        error.value = result.error!.message ?? 'Purchase failed';
        return;
      }

      await refreshStatus();
    } catch (e) {
      print("eeerrrear ${e}");

      error.value = '$e';
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> restore() async {
    try {
      isBusy.value = true;
      error.value = null;
      await _service.restorePurchases();
      await refreshStatus();
    } catch (e,stacktrace) {
      print("VDSVDSVDS ${e} ${stacktrace}");
      error.value = '$e';
    } finally {
      isBusy.value = false;
    }
  }
}

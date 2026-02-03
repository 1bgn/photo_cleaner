import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_paywall.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/di.dart';
import '../presentation/monetization_controller.dart';

class MainPaywallSheet extends StatefulWidget {
  const MainPaywallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const MainPaywallSheet(),
    );
  }

  @override
  State<MainPaywallSheet> createState() => _MainPaywallSheetState();
}

class _MainPaywallSheetState extends State<MainPaywallSheet> {
  late final MonetizationController c;

  @override
  void initState() {
    super.initState();
    c = getIt<MonetizationController>();
    c.init();
  }

  ApphudProduct? _findProduct(ApphudPaywall pw, String productId) {
    final list = pw.products ?? const <ApphudProduct>[];
    for (final p in list) {
      if (p.productId == productId) return p;
    }
    return null;
  }

  String _priceLabel(ApphudProduct p) {
    final sk = p.skProduct;
    if (sk != null && sk.price != null) {
      final price = sk.price!;
      final symbol = sk.priceLocale.currencySymbol;
      final code = sk.priceLocale.currencyCode;
      final v = price.toStringAsFixed(2);

      if (symbol != null && symbol.isNotEmpty) return '$symbol$v';
      if (code != null && code.isNotEmpty) return '$v $code';
      return v;
    }
    return '—';
  }

  Future<void> _buy(String productId) async {
    final pw = c.paywall.value;
    if (pw == null) return;

    final p = _findProduct(pw, productId);
    if (p == null) return;

    if (productId == 'sonicforge_weekly') {
      await c.buyWeekly();
    } else {
      await c.buyMonthly();
    }

    if (!mounted) return;
    if (c.hasPremium.value) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final busy = c.isBusy.watch(context);
      final ready = c.isReady.watch(context);
      final premium = c.hasPremium.watch(context);
      final err = c.error.watch(context);
      final pw = c.paywall.watch(context);

      final maxH = MediaQuery.of(context).size.height * 0.85;

      if (premium) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'SonicForge Pro',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'subscriptionAlreadyActive'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    child: Text('ok'.tr()),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final weekly = (pw == null) ? null : _findProduct(pw, 'sonicforge_weekly');
      final monthly = (pw == null) ? null : _findProduct(pw, 'sonicforge_monthly');

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'SonicForge Pro',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!ready || busy) const LinearProgressIndicator(),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 12),

                const _Benefits(),
                const SizedBox(height: 12),

                if (pw == null) ...[
                  const SizedBox(height: 12),
                  Text('paywallNotLoaded'.tr()),
                ] else ...[
                  _PlanTile(
                    title: 'Weekly',
                    subtitle: 'billedWeekly'.tr(),
                    price: weekly == null ? '—' : _priceLabel(weekly),
                    highlighted: true,
                    onPressed: (busy || weekly == null) ? null : () => _buy('sonicforge_weekly'),
                  ),
                  const SizedBox(height: 10),
                  _PlanTile(
                    title: 'Monthly',
                    subtitle: 'bestValue'.tr(),
                    price: monthly == null ? '—' : _priceLabel(monthly),
                    highlighted: false,
                    onPressed: (busy || monthly == null) ? null : () => _buy('sonicforge_monthly'),
                  ),
                ],

                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton(
                      onPressed: busy
                          ? null
                          : () async {
                        await c.restore();
                        if (!mounted) return;
                        if (c.hasPremium.value) Navigator.pop(context);
                      },
                      child: Text('restorePurchases'.tr()),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      child: Text('notNow'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('proBenefitsTitle'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _Bullet('noAds'.tr()),
        _Bullet('moreProcessingLimits'.tr()),
        _Bullet('hdExport'.tr()),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.highlighted,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool highlighted;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: highlighted ? 2 : 1,
          color: highlighted ? Theme.of(context).colorScheme.primary : Colors.black12,
        ),
      ),
      child: ListTile(
        isThreeLine: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: SizedBox(
          width: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text('continue'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

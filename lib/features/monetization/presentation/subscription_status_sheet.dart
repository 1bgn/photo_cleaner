import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/di.dart';
import '../presentation/monetization_controller.dart';

class SubscriptionStatusSheet extends StatefulWidget {
  const SubscriptionStatusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SubscriptionStatusSheet(),
    );
  }

  @override
  State<SubscriptionStatusSheet> createState() => _SubscriptionStatusSheetState();
}

class _SubscriptionStatusSheetState extends State<SubscriptionStatusSheet> {
  late final MonetizationController c;

  @override
  void initState() {
    super.initState();
    c = getIt<MonetizationController>();
    _check();
  }

  Future<void> _check() => c.checkSubscriptionStatus(forceSync: true);


  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final busy = c.isBusy.watch(context);
      final err = c.error.watch(context);
      final hasSub = c.hasSubcription.watch(context);

      final maxH = MediaQuery.of(context).size.height * 0.55;

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
                    Expanded(
                      child: Text(
                        'checkSubscriptionTitle'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (busy) const LinearProgressIndicator(),
                if (err != null) ...[
                  const SizedBox(height: 10),
                  Text(err, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 14),

                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      hasSub ? Icons.verified : Icons.info_outline,
                      color: hasSub ? Colors.green : null,
                    ),
                    title: Text('subscriptionStatusTitle'.tr()),
                    subtitle: Text(
                      hasSub
                          ? 'subscriptionStatusActive'.tr()
                          : 'subscriptionStatusInactive'.tr(),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton(
                      onPressed: busy ? null : _check,
                      child: Text('checkAgain'.tr()),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      child: Text('close'.tr()),
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

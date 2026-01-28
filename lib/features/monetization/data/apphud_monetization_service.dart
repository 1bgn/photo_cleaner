import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'apphud_listener_bridge.dart';

class ApphudMonetizationService {
  ApphudListenerBridge? _listener;

  ApphudPaywalls? _paywallsCache;
  List<ApphudPlacement> _placementsCache = const [];
  bool _premium = false;

  Future<void> init() async {
    _listener = ApphudListenerBridge(
      onSubscriptionsUpdated: (_) async {
        // проще всего пересчитать статус через SDK
        _premium = await Apphud.hasPremiumAccess();
      },
      onPaywallsLoaded: (pw) {
        _paywallsCache = pw;
      },
      onPlacementsLoaded: (pl) {
        _placementsCache = pl;
      },
    );

    await Apphud.setListener(listener: _listener);
    await Apphud.start(apiKey: 'app_Z44sHCCXqhP5FCBDa8SxKBLB7VLpga');
  }

  bool get premiumCached => _premium;
  ApphudPaywalls? get paywallsCached => _paywallsCache;
  List<ApphudPlacement> get placementsCached => _placementsCache;
}

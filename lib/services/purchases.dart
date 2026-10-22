import '../data/models.dart';
import '../data/packs.dart';
import '../data/progress.dart';

/// Buying packs. The app talks only to this, so the real App Store and
/// Google Play billing can replace [PretendPurchases] without touching screens.
abstract class Purchases {
  /// Buys one pack. Returns true if the child now has it.
  Future<bool> buyPack(SpotPack pack);

  /// Buys every pack, now and in future.
  Future<bool> buyFamilyPass();

  /// Brings back packs bought on another device or before a reinstall.
  Future<void> restore();
}

/// Stands in for the stores during testing: every purchase succeeds and
/// nothing is charged.
class PretendPurchases implements Purchases {
  PretendPurchases(this._progress);

  final Progress _progress;

  @override
  Future<bool> buyPack(SpotPack pack) async {
    _progress.unlock([pack]);
    return true;
  }

  @override
  Future<bool> buyFamilyPass() async {
    _progress.unlock(playablePacks);
    return true;
  }

  @override
  Future<void> restore() async {}
}

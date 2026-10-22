import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'packs.dart';

/// A spot the child has made: the points it earned and when.
@immutable
class Spot {
  const Spot(this.points, this.at);

  final int points;
  final DateTime at;

  Map<String, Object> toJson() => {'pts': points, 'at': at.millisecondsSinceEpoch};

  static Spot fromJson(Map<String, dynamic> j) =>
      Spot(j['pts'] as int, DateTime.fromMillisecondsSinceEpoch(j['at'] as int));
}

/// The result of spotting something, used to drive the celebration.
@immutable
class SpotResult {
  const SpotResult({required this.points, required this.golden, required this.before, required this.after, this.newMedal});

  final int points;
  final bool golden;
  final int before;
  final int after;
  final Medal? newMedal;
}

/// Everything the child has done, saved on the device only.
///
/// Nothing here leaves the device: no accounts and no analytics.
class Progress extends ChangeNotifier {
  Progress(this._prefs, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _load();
  }

  static const _key = 'progress.v1';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  final Map<String, Map<String, Spot>> _found = {};
  final Set<String> _unlocked = {};
  String _name = '';
  int _huntWins = 0;
  String _currentPackId = airportPack.id;

  static Future<Progress> open() async => Progress(await SharedPreferences.getInstance());

  String get name => _name;

  /// The pack the child last opened. The album and badges show this one.
  SpotPack get currentPack => packById(_currentPackId);
  set currentPack(SpotPack pack) {
    if (pack.id == _currentPackId) return;
    _currentPackId = pack.id;
    _save();
  }
  int get huntWins => _huntWins;

  bool isOpen(SpotPack pack) => !pack.comingSoon && (pack.free || _unlocked.contains(pack.id));
  bool get hasFamilyPass => playablePacks.every(isOpen);

  Map<String, Spot> foundIn(SpotPack pack) => Map.unmodifiable(_found[pack.id] ?? const {});
  bool isFound(SpotPack pack, SpotItem item) => _found[pack.id]?.containsKey(item.id) ?? false;
  int foundCount(SpotPack pack) => _found[pack.id]?.length ?? 0;

  int pointsIn(SpotPack pack) => (_found[pack.id]?.values ?? const <Spot>[]).fold(0, (s, f) => s + f.points);
  int get totalPoints => playablePacks.fold(0, (s, p) => s + pointsIn(p));
  int get totalFound => playablePacks.fold(0, (s, p) => s + foundCount(p));
  int get totalMedals => playablePacks.fold(0, (s, p) => s + medalCount(p));

  Medal? medalIn(SpotPack pack) => Medal.forPoints(pointsIn(pack));
  int medalCount(SpotPack pack) => Medal.values.where((m) => pointsIn(pack) >= m.points).length;

  SpotItem golden(SpotPack pack) => pack.goldenFor(_clock());
  bool isGolden(SpotPack pack, SpotItem item) => golden(pack).id == item.id;

  /// What spotting [item] is worth now, or what it earned if already spotted.
  int valueOf(SpotPack pack, SpotItem item) =>
      _found[pack.id]?[item.id]?.points ?? (isGolden(pack, item) ? item.points * 2 : item.points);

  SpotResult spot(SpotPack pack, SpotItem item) {
    final before = pointsIn(pack);
    final golden = isGolden(pack, item);
    final points = golden ? item.points * 2 : item.points;
    (_found[pack.id] ??= {})[item.id] = Spot(points, _clock());
    final after = pointsIn(pack);
    Medal? newMedal;
    for (final m in Medal.values) {
      if (before < m.points && after >= m.points) newMedal = m;
    }
    _save();
    return SpotResult(points: points, golden: golden, before: before, after: after, newMedal: newMedal);
  }

  void unspot(SpotPack pack, SpotItem item) {
    _found[pack.id]?.remove(item.id);
    _save();
  }

  void resetPack(SpotPack pack) {
    _found.remove(pack.id);
    _save();
  }

  void unlock(Iterable<SpotPack> packs) {
    _unlocked.addAll(packs.map((p) => p.id));
    _save();
  }

  set name(String value) {
    final v = value.trim();
    _name = v.length > 20 ? v.substring(0, 20) : v;
    _save();
  }

  void addHuntWin() {
    _huntWins++;
    _save();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _name = j['name'] as String? ?? '';
      _huntWins = j['huntWins'] as int? ?? 0;
      final current = j['current'] as String?;
      if (current != null && allPacks.any((p) => p.id == current && !p.comingSoon)) _currentPackId = current;
      _unlocked.addAll((j['unlocked'] as List? ?? const []).cast<String>());
      final packs = j['packs'] as Map<String, dynamic>? ?? const {};
      for (final e in packs.entries) {
        _found[e.key] = (e.value as Map<String, dynamic>).map((id, s) => MapEntry(id, Spot.fromJson(s as Map<String, dynamic>)));
      }
    } on FormatException {
      // A damaged save starts fresh rather than crashing the app.
    } on TypeError {
      // Same for a save written in an unexpected shape.
    }
  }

  void _save() {
    _prefs.setString(
      _key,
      jsonEncode({
        'name': _name,
        'huntWins': _huntWins,
        'current': _currentPackId,
        'unlocked': _unlocked.toList(),
        'packs': _found.map((k, v) => MapEntry(k, v.map((id, s) => MapEntry(id, s.toJson())))),
      }),
    );
    notifyListeners();
  }
}

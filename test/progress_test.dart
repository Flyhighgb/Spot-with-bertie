import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_with_bertie/data/models.dart';
import 'package:spot_with_bertie/data/packs.dart';
import 'package:spot_with_bertie/data/progress.dart';

void main() {
  final day = DateTime(2026, 10, 22);

  Future<Progress> fresh([Map<String, Object> saved = const {}]) async {
    SharedPreferences.setMockInitialValues(saved);
    return Progress(await SharedPreferences.getInstance(), clock: () => day);
  }

  SpotItem notGolden(SpotPack pack) => pack.items.firstWhere((i) => i.id != pack.goldenFor(day).id);

  test('every playable pack has 24 items worth 350 points with art', () {
    for (final pack in playablePacks) {
      expect(pack.items, hasLength(24), reason: pack.name);
      expect(pack.totalPoints, 350, reason: pack.name);
      expect(pack.items.map((i) => i.id).toSet(), hasLength(24), reason: '${pack.name} ids are unique');
      for (final item in pack.items) {
        expect(item.image, startsWith('assets/images/'));
        expect(item.fact, isNotEmpty);
      }
    }
  });

  test('only the airport is open at first', () async {
    final p = await fresh();
    expect(p.isOpen(airportPack), isTrue);
    expect(p.isOpen(parkPack), isFalse);
    expect(p.isOpen(seasidePack), isFalse);
    expect(p.hasFamilyPass, isFalse);
  });

  test('spotting adds the item points', () async {
    final p = await fresh();
    final item = notGolden(airportPack);
    final r = p.spot(airportPack, item);
    expect(r.points, item.points);
    expect(r.golden, isFalse);
    expect(p.pointsIn(airportPack), item.points);
    expect(p.isFound(airportPack, item), isTrue);
    expect(p.totalFound, 1);
  });

  test("today's golden spot is worth double, and keeps its value tomorrow", () async {
    final p = await fresh();
    final golden = airportPack.goldenFor(day);
    expect(p.valueOf(airportPack, golden), golden.points * 2);
    final r = p.spot(airportPack, golden);
    expect(r.golden, isTrue);
    expect(r.points, golden.points * 2);
    expect(p.pointsIn(airportPack), golden.points * 2);
  });

  test('the golden spot changes each day', () {
    final days = {for (var d = 0; d < 7; d++) airportPack.goldenFor(day.add(Duration(days: d))).id};
    expect(days.length, greaterThan(1));
  });

  test('badges are awarded once as points cross 50, 125 and 200', () async {
    final p = await fresh();
    final awarded = <Medal>[];
    for (final item in airportPack.items) {
      final m = p.spot(airportPack, item).newMedal;
      if (m != null) awarded.add(m);
    }
    expect(awarded, Medal.values);
    expect(p.medalIn(airportPack), Medal.gold);
    expect(p.medalCount(airportPack), 3);
    expect(p.totalMedals, 3);
  });

  test('unspot and reset take points away', () async {
    final p = await fresh();
    final item = notGolden(airportPack);
    p.spot(airportPack, item);
    p.unspot(airportPack, item);
    expect(p.pointsIn(airportPack), 0);
    p.spot(airportPack, item);
    p.resetPack(airportPack);
    expect(p.foundCount(airportPack), 0);
  });

  test('progress, name and purchases survive a restart', () async {
    final p = await fresh();
    final item = notGolden(airportPack);
    p.spot(airportPack, item);
    p.name = '  Alexandra-Charlotte Smith  ';
    p.unlock([parkPack]);
    p.currentPack = parkPack;

    final again = Progress(await SharedPreferences.getInstance(), clock: () => day);
    expect(again.isFound(airportPack, item), isTrue);
    expect(again.pointsIn(airportPack), item.points);
    expect(again.name, 'Alexandra-Charlotte ');
    expect(again.isOpen(parkPack), isTrue);
    expect(again.isOpen(trainPack), isFalse);
    expect(again.currentPack, parkPack);
  });

  test('unlocking every pack is the family pass', () async {
    final p = await fresh();
    p.unlock(playablePacks);
    expect(p.hasFamilyPass, isTrue);
    expect(p.isOpen(seasidePack), isFalse);
  });

  test('a damaged save starts fresh', () async {
    final p = await fresh({'progress.v1': '{not json'});
    expect(p.totalPoints, 0);
    final q = await fresh({'progress.v1': '{"packs": {"airport": 3}}'});
    expect(q.totalPoints, 0);
  });
}

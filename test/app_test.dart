import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spot_with_bertie/data/packs.dart';
import 'package:spot_with_bertie/data/progress.dart';
import 'package:spot_with_bertie/services/purchases.dart';
import 'package:spot_with_bertie/ui/app.dart';

void main() {
  late Progress progress;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    progress = Progress(await SharedPreferences.getInstance());
  });

  // Lets a sheet or dialog finish sliding in, without waiting on Bertie's endless bobbing.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SpotApp(progress: progress, purchases: PretendPurchases(progress)));
    await tester.pump();
  }

  testWidgets('spot something at the airport', (tester) async {
    await pumpApp(tester);
    expect(find.text('Where shall we spot today?'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(find.textContaining("Today's golden spot"), findsOneWidget);

    final item = airportPack.items.firstWhere((i) => !progress.isGolden(airportPack, i));
    await tester.tap(find.text(item.name).first);
    await settle(tester);
    expect(find.text(item.fact), findsOneWidget);

    await tester.tap(find.text('I spotted it!'));
    await settle(tester);
    expect(progress.isFound(airportPack, item), isTrue);
    expect(find.text('+${item.points} points'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('buying a pack needs the grown-up answer', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Park'));
    await settle(tester);
    await tester.tap(find.text('Get it for 99p'));
    await settle(tester);
    expect(find.text('Grown-ups only'), findsOneWidget);

    final question = tester.widget<Text>(find.textContaining('What is ')).data!;
    final nums = RegExp(r'\d+').allMatches(question).map((m) => int.parse(m[0]!)).toList();

    await tester.enterText(find.byKey(const Key('grownUpAnswer')), '1');
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(find.text('Not quite. Try again.'), findsOneWidget);
    expect(progress.isOpen(parkPack), isFalse);

    await tester.enterText(find.byKey(const Key('grownUpAnswer')), '${nums[0] * nums[1]}');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(progress.isOpen(parkPack), isTrue);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('album and badges tabs open', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Stickers'));
    await settle(tester);
    expect(find.text('Sticker album'), findsOneWidget);
    await tester.tap(find.text('Badges').last);
    await settle(tester);
    expect(find.text('Gold'), findsNWidgets(playablePacks.length));
    await tester.scrollUntilVisible(find.text('For grown-ups'), 300);
    expect(find.text('Restore purchases'), findsOneWidget);
  });
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../data/packs.dart';
import 'progress_scope.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/hex_badge.dart';

/// Asks a sum a young child is unlikely to answer, before buying or resetting.
Future<bool> askGrownUp(BuildContext context, {required String reason, math.Random? random}) async {
  final rnd = random ?? math.Random();
  final a = 6 + rnd.nextInt(4), b = 3 + rnd.nextInt(7);
  final answer = await showDialog<bool>(context: context, builder: (_) => _GrownUpGate(a: a, b: b, reason: reason));
  return answer ?? false;
}

class _GrownUpGate extends StatefulWidget {
  const _GrownUpGate({required this.a, required this.b, required this.reason});

  final int a, b;
  final String reason;

  @override
  State<_GrownUpGate> createState() => _GrownUpGateState();
}

class _GrownUpGateState extends State<_GrownUpGate> {
  final _text = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _check() {
    if (int.tryParse(_text.text.trim()) == widget.a * widget.b) {
      Navigator.pop(context, true);
    } else {
      setState(() => _wrong = true);
      _text.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Grown-ups only'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('To ${widget.reason}, please answer:', style: t.bodyMedium),
        const SizedBox(height: 12),
        Text('What is ${widget.a} × ${widget.b}?', style: t.titleLarge),
        const SizedBox(height: 12),
        TextField(
          key: const Key('grownUpAnswer'),
          controller: _text,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _check(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            errorText: _wrong ? 'Not quite. Try again.' : null,
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _check, child: const Text('OK')),
      ],
    );
  }
}

/// Shows what a pack contains and lets a grown-up buy it.
Future<void> offerPack(BuildContext context, SpotPack pack) {
  return _offer(
    context,
    icon: pack.icon,
    title: '${pack.name} pack',
    blurb: pack.blurb,
    price: pack.price,
    preview: pack.items.take(6).map((i) => i.image).toList(),
    buy: () => ProgressScope.purchasesOf(context).buyPack(pack),
    done: 'The ${pack.name} pack is open. Happy spotting!',
  );
}

/// Offers every pack at once.
Future<void> offerFamilyPass(BuildContext context) {
  return _offer(
    context,
    icon: bertieImage,
    title: 'Family pass',
    blurb: 'Every pack, now and in future, for the whole family. Includes the Park and Train station packs, and Seaside when it lands.',
    price: familyPassPrice,
    preview: [for (final p in playablePacks) p.icon],
    buy: () => ProgressScope.purchasesOf(context).buyFamilyPass(),
    done: 'Every pack is open. Happy spotting!',
  );
}

Future<void> _offer(
  BuildContext context, {
  required String icon,
  required String title,
  required String blurb,
  required String price,
  required List<String> preview,
  required Future<bool> Function() buy,
  required String done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final go = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (context) {
      final t = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            HexBadge(style: HexStyle.purple, size: 96, child: Image.asset(icon)),
            const SizedBox(height: 8),
            Text(title, style: t.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(blurb, style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final p in preview)
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: SpotColors.accentSoft, borderRadius: BorderRadius.circular(14)),
                  child: Image.asset(p),
                ),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Get it for $price'))),
            const SizedBox(height: 6),
            Text('No ads, ever. A grown-up will need to say yes.', style: t.bodySmall?.copyWith(color: SpotColors.inkSoft)),
          ]),
        ),
      );
    },
  );
  if (go != true || !context.mounted) return;
  if (!await askGrownUp(context, reason: 'buy $title')) return;
  if (await buy()) {
    if (context.mounted) showConfetti(context);
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }
}

/// Lets the child type the name shown on certificates.
Future<void> editName(BuildContext context) async {
  final progress = ProgressScope.of(context);
  final text = TextEditingController(text: progress.name);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text("What's your name?"),
      content: TextField(
        controller: text,
        autofocus: true,
        maxLength: 20,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (v) => Navigator.pop(context, v),
        decoration: InputDecoration(hintText: 'Your name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, text.text), child: const Text('Save')),
      ],
    ),
  );
  text.dispose();
  if (name != null) progress.name = name;
}

/// Celebrates a new badge. Gold comes with a certificate.
Future<void> showMedal(BuildContext context, SpotPack pack, Medal medal) {
  final progress = ProgressScope.of(context);
  showConfetti(context, count: 80);
  return showDialog(
    context: context,
    builder: (context) {
      final t = Theme.of(context).textTheme;
      final style = HexStyle.values.byName(medal.name);
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (medal == Medal.gold) ...[
              Text('Certificate', style: t.titleMedium?.copyWith(color: SpotColors.accent, letterSpacing: 2)),
              const SizedBox(height: 8),
            ],
            HexBadge(style: style, size: 120, child: Image.asset(pack.icon)),
            const SizedBox(height: 12),
            Text(medal.title, style: t.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              medal == Medal.gold
                  ? '${progress.name.isEmpty ? 'You' : progress.name} scored ${progress.pointsIn(pack)} points at the ${pack.place}. ${medal.blurb}'
                  : '${medal.blurb} You reached ${medal.points} points at the ${pack.place}.',
              style: t.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Hooray!'))),
          ]),
        ),
      );
    },
  );
}

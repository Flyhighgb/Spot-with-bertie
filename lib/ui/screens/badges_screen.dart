import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/packs.dart';
import '../dialogs.dart';
import '../progress_scope.dart';
import '../widgets/common.dart';
import '../widgets/hex_badge.dart';

/// Bronze, silver and gold for each pack, and the grown-ups' corner.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final t = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      StatsBar(progress: progress),
      const SizedBox(height: 14),
      Text('Badges', style: t.headlineLarge),
      const SizedBox(height: 12),
      for (final pack in playablePacks) ...[
        SpotCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pack.name, style: t.titleLarge),
            Text('${progress.pointsIn(pack)} of ${pack.totalPoints} pts', style: t.bodyMedium),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              for (final m in Medal.values)
                Builder(builder: (context) {
                  final earned = progress.pointsIn(pack) >= m.points;
                  return GestureDetector(
                    onTap: earned ? () => showMedal(context, pack, m) : null,
                    child: Column(children: [
                      HexBadge(style: earned ? HexStyle.values.byName(m.name) : HexStyle.locked, size: 76, locked: !earned, child: Image.asset(pack.icon)),
                      Text(m.label, style: t.titleMedium),
                      Text('${m.points} pts', style: t.bodySmall),
                    ]),
                  );
                }),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 8),
      const _GrownUps(),
    ]);
  }
}

/// Restore purchases and reset progress, both behind the grown-up question.
class _GrownUps extends StatelessWidget {
  const _GrownUps();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final progress = ProgressScope.of(context);
    return SpotCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('For grown-ups', style: t.titleLarge),
        const SizedBox(height: 4),
        Text('Spot with Bertie has no ads and no accounts. Progress stays on this device.', style: t.bodyMedium),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            if (!await askGrownUp(context, reason: 'restore purchases') || !context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            await ProgressScope.purchasesOf(context).restore();
            messenger.showSnackBar(const SnackBar(content: Text('Purchases restored.')));
          },
          child: const Text('Restore purchases'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            final pack = progress.currentPack;
            if (!await askGrownUp(context, reason: 'clear the ${pack.name} pack') || !context.mounted) return;
            progress.resetPack(pack);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('The ${pack.name} pack is cleared.')));
          },
          child: Text('Start the ${progress.currentPack.name} pack again'),
        ),
      ]),
    );
  }
}

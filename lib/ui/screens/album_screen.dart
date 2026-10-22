import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/packs.dart';
import '../dialogs.dart';
import '../progress_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _greyscale = ColorFilter.matrix([
  0.2, 0.2, 0.2, 0, 40, //
  0.2, 0.2, 0.2, 0, 40,
  0.2, 0.2, 0.2, 0, 50,
  0, 0, 0, 0.35, 0,
]);

/// A sticker for every thing spotted. Things still to find are greyed out.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final pack = progress.currentPack;
    final t = Theme.of(context).textTheme;
    final found = progress.foundIn(pack);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      StatsBar(progress: progress),
      const SizedBox(height: 14),
      Text('Sticker album', style: t.headlineLarge),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        for (final p in playablePacks)
          ChoiceChip(
            label: Text(p.name),
            avatar: progress.isOpen(p) ? null : const Icon(Icons.lock_rounded, size: 18),
            selected: p.id == pack.id,
            onSelected: (_) => progress.isOpen(p) ? progress.currentPack = p : offerPack(context, p),
          ),
      ]),
      const SizedBox(height: 10),
      Text('${found.length} of ${pack.items.length} stickers', style: t.bodyMedium),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
        children: [for (final item in pack.items) _Sticker(item: item, spottedOn: found[item.id]?.at)],
      ),
    ]);
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.item, required this.spottedOn});

  final SpotItem item;
  final DateTime? spottedOn;

  @override
  Widget build(BuildContext context) {
    final got = spottedOn != null;
    final image = Image.asset(item.image, fit: BoxFit.contain);
    return Semantics(
      label: got ? '${item.name} sticker' : 'Sticker still to find',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: got ? Colors.white : SpotColors.line,
          borderRadius: BorderRadius.circular(20),
          boxShadow: got ? spotShadow : null,
        ),
        child: Column(children: [
          Expanded(child: got ? image : ColorFiltered(colorFilter: _greyscale, child: image)),
          const SizedBox(height: 4),
          Text(
            got ? item.name : '?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w700, fontSize: 13, color: got ? SpotColors.ink : SpotColors.locked),
          ),
          if (got) Text('${spottedOn!.day}/${spottedOn!.month}/${spottedOn!.year}', style: const TextStyle(fontSize: 11, color: SpotColors.inkSoft)),
        ]),
      ),
    );
  }
}

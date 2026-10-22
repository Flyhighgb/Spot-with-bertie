import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/progress.dart';
import '../dialogs.dart';
import '../progress_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum _Filter { all, toFind, spotted }

/// Everything to spot in one pack, with points and the next badge to aim for.
class PackScreen extends StatefulWidget {
  const PackScreen({super.key, required this.pack});

  final SpotPack pack;

  @override
  State<PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends State<PackScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final pack = widget.pack;
    final t = Theme.of(context).textTheme;
    final items = pack.items.where((i) => switch (_filter) {
          _Filter.all => true,
          _Filter.toFind => !progress.isFound(pack, i),
          _Filter.spotted => progress.isFound(pack, i),
        }).toList();
    final golden = progress.golden(pack);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [SpotColors.sky1, SpotColors.sky2])),
        child: SafeArea(
          child: CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.list(children: [
                StatsBar(
                  progress: progress,
                  trailing: IconButton.filledTonal(
                    tooltip: 'Back to the map',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Text(pack.name, style: t.headlineLarge),
                const SizedBox(height: 10),
                _MedalProgress(progress: progress, pack: pack),
                const SizedBox(height: 12),
                SpotCard(
                  color: const Color(0xFFFFF6E3),
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  onTap: () => _openItem(context, golden),
                  child: Row(children: [
                    Image.asset(bertieImage, width: 64),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: "Today's golden spot is the "),
                          TextSpan(text: golden.name.toLowerCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFA86A00))),
                          const TextSpan(text: '. Spot it for double points!'),
                        ]),
                        style: t.bodyLarge,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                SegmentedButton<_Filter>(
                  showSelectedIcon: false,
                  segments: [
                    const ButtonSegment(value: _Filter.all, label: Text('All')),
                    ButtonSegment(value: _Filter.toFind, label: Text('To find (${pack.items.length - progress.foundCount(pack)})')),
                    ButtonSegment(value: _Filter.spotted, label: Text('Spotted (${progress.foundCount(pack)})')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
                const SizedBox(height: 14),
              ]),
            ),
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(_filter == _Filter.spotted ? 'Nothing spotted yet. Have a look around!' : 'You spotted everything. Amazing!', style: t.bodyLarge, textAlign: TextAlign.center),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82),
                itemCount: items.length,
                itemBuilder: (context, i) => _ItemCard(pack: pack, item: items[i], progress: progress, onTap: () => _openItem(context, items[i])),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _openItem(BuildContext context, SpotItem item) async {
    final pack = widget.pack;
    final result = await showModalBottomSheet<SpotResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => ItemSheet(pack: pack, item: item),
    );
    if (result == null || !context.mounted) return;
    showConfetti(context, count: result.golden ? 70 : 40);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(result.golden ? 'Golden spot! +${result.points} points' : '+${result.points} points'),
    ));
    if (result.newMedal != null) await showMedal(context, pack, result.newMedal!);
  }
}

class _MedalProgress extends StatelessWidget {
  const _MedalProgress({required this.progress, required this.pack});

  final Progress progress;
  final SpotPack pack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pts = progress.pointsIn(pack);
    final next = Medal.nextAfter(pts);
    final from = Medal.forPoints(pts)?.points ?? 0;
    final value = next == null ? 1.0 : (pts - from) / (next.points - from);
    return SpotCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('$pts pts', style: t.titleLarge),
          const Spacer(),
          Text(next == null ? 'Gold Spotter!' : '${next.points - pts} to ${next.label}', style: t.bodyMedium),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 14,
            backgroundColor: SpotColors.line,
            color: switch (next) { Medal.bronze => SpotColors.bronze, Medal.silver => SpotColors.silver, Medal.gold || null => SpotColors.goldMedal },
          ),
        ),
        const SizedBox(height: 6),
        Text('${progress.foundCount(pack)} of ${pack.items.length} spotted', style: t.bodyMedium),
      ]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.pack, required this.item, required this.progress, required this.onTap});

  final SpotPack pack;
  final SpotItem item;
  final Progress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final found = progress.isFound(pack, item);
    final golden = progress.isGolden(pack, item);
    return Semantics(
      button: true,
      label: '${item.name}, ${progress.valueOf(pack, item)} points${found ? ', spotted' : ''}${golden ? ', golden spot' : ''}',
      excludeSemantics: true,
      child: Material(
        color: SpotColors.tier(item.points),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: golden ? BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: SpotColors.gold, width: 3)) : null,
            padding: const EdgeInsets.all(10),
            child: Stack(children: [
              Column(children: [
                Expanded(child: Image.asset(item.image, fit: BoxFit.contain)),
                const SizedBox(height: 6),
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                PointsPill(tier: item.points, value: progress.valueOf(pack, item)),
              ]),
              if (found)
                const Positioned(right: 0, top: 0, child: CircleAvatar(radius: 14, backgroundColor: SpotColors.green, child: Icon(Icons.check_rounded, color: Colors.white, size: 18))),
              if (golden && !found) const Positioned(left: 0, top: 0, child: Icon(Icons.auto_awesome_rounded, color: SpotColors.gold, size: 24)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One item, its fun fact, and the button to say it was spotted.
/// Pops with a [SpotResult] when the child spots it.
class ItemSheet extends StatelessWidget {
  const ItemSheet({super.key, required this.pack, required this.item});

  final SpotPack pack;
  final SpotItem item;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final t = Theme.of(context).textTheme;
    final found = progress.isFound(pack, item);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: SpotColors.tier(item.points), borderRadius: BorderRadius.circular(28)),
            child: Image.asset(item.image),
          ),
          const SizedBox(height: 14),
          Text(item.name, style: t.headlineMedium),
          const SizedBox(height: 6),
          PointsPill(tier: item.points, value: progress.valueOf(pack, item), big: true),
          if (progress.isGolden(pack, item) && !found) ...[
            const SizedBox(height: 6),
            Text("Today's golden spot: double points!", style: t.bodyMedium?.copyWith(color: const Color(0xFFA86A00))),
          ],
          const SizedBox(height: 12),
          Text(item.fact, style: t.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: found
                ? OutlinedButton(onPressed: () {
                    progress.unspot(pack, item);
                    Navigator.pop(context);
                  }, child: const Text('Oops, not spotted yet'))
                : FilledButton.icon(
                    onPressed: () => Navigator.pop(context, progress.spot(pack, item)),
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('I spotted it!'),
                  ),
          ),
        ]),
      ),
    );
  }
}

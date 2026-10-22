import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../theme.dart';

const bertieImage = 'assets/images/bertie.webp';

/// Bertie the plane, gently bobbing and tilting as if flying.
class FlyingBertie extends StatefulWidget {
  const FlyingBertie({super.key, this.size = 120});

  final double size;

  @override
  State<FlyingBertie> createState() => _FlyingBertieState();
}

class _FlyingBertieState extends State<FlyingBertie> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = still ? 0.0 : _c.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * widget.size * 0.05),
          child: Transform.rotate(angle: math.sin(t + 1) * 0.05, child: child),
        );
      },
      child: Image.asset(bertieImage, width: widget.size, semanticLabel: 'Bertie the plane'),
    );
  }
}

/// White rounded card with the app's soft shadow.
class SpotCard extends StatelessWidget {
  const SpotCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = SpotColors.card, this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      shadowColor: const Color(0x334B3278),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Stars, things spotted and badges, across every pack.
class StatsBar extends StatelessWidget {
  const StatsBar({super.key, required this.progress, this.trailing});

  final Progress progress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    Widget stat(IconData icon, Color color, int value, String label) => Semantics(
          label: '$value $label',
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 4),
              Text('$value', style: Theme.of(context).textTheme.titleMedium),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: spotShadow),
      child: Row(children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(children: [
              stat(Icons.star_rounded, SpotColors.gold, progress.totalPoints, 'points'),
              stat(Icons.diamond_rounded, SpotColors.grass, progress.totalFound, 'things spotted'),
              stat(Icons.military_tech_rounded, const Color(0xFFEF6A5A), progress.totalMedals, 'badges'),
            ]),
          ),
        ),
        trailing ??
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFFFF6E8), Color(0xFFFFD9B8)])),
              padding: const EdgeInsets.all(4),
              child: Image.asset(bertieImage),
            ),
      ]),
    );
  }
}

/// A coloured pill showing an item's points.
class PointsPill extends StatelessWidget {
  const PointsPill({super.key, required this.tier, required this.value, this.big = false});

  final int tier;
  final int value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 12 : 9, vertical: 3),
      decoration: BoxDecoration(color: SpotColors.tier(tier), borderRadius: BorderRadius.circular(999)),
      child: Text('$value pts', style: TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w800, fontSize: big ? 16 : 13, color: SpotColors.tierText(tier))),
    );
  }
}

/// Bursts of confetti over the whole screen.
void showConfetti(BuildContext context, {Offset? from, int count = 40}) {
  if (MediaQuery.of(context).disableAnimations) return;
  final overlay = Overlay.of(context);
  final size = MediaQuery.of(context).size;
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Confetti(origin: from ?? Offset(size.width / 2, size.height / 3), count: count, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.origin, required this.count, required this.onDone});

  final Offset origin;
  final int count;
  final VoidCallback onDone;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  static const _colors = [Color(0xFFF6B23B), Color(0xFFE8762E), Color(0xFF8D62DC), Color(0xFF79C158), Color(0xFF5AB8EC), Color(0xFFFF8FB1)];
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..forward().whenComplete(widget.onDone);
  final _rnd = math.Random();
  late final _bits = List.generate(widget.count, (i) {
    final a = _rnd.nextDouble() * 2 * math.pi, d = 60 + _rnd.nextDouble() * 160;
    return (dx: math.cos(a) * d, dy: math.sin(a) * d, spin: _rnd.nextDouble() * 12 - 6, color: _colors[i % _colors.length], round: i % 3 == 0);
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return Stack(children: [
            for (final b in _bits)
              Positioned(
                left: widget.origin.dx + b.dx * t,
                top: widget.origin.dy + b.dy * t + 140 * _c.value * _c.value,
                child: Opacity(
                  opacity: 1 - _c.value,
                  child: Transform.rotate(
                    angle: b.spin * _c.value,
                    child: Container(width: 9, height: b.round ? 9 : 14, decoration: BoxDecoration(color: b.color, borderRadius: BorderRadius.circular(b.round ? 9 : 2))),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

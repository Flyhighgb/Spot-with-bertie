import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/packs.dart';
import '../../data/progress.dart';
import '../dialogs.dart';
import '../progress_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/hex_badge.dart';
import 'pack_screen.dart';

/// The island map: one stop per pack, with Bertie flying by the current one.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static void openPack(BuildContext context, SpotPack pack) {
    final progress = ProgressScope.of(context);
    if (pack.comingSoon) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('The ${pack.name} pack is coming soon!')));
    } else if (!progress.isOpen(pack)) {
      offerPack(context, pack);
    } else {
      progress.currentPack = pack;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PackScreen(pack: pack)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        StatsBar(
          progress: progress,
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: TextButton.icon(
              onPressed: () => editName(context),
              icon: const Icon(Icons.face_rounded, color: SpotColors.accent),
              label: Text(progress.name.isEmpty ? 'Add name' : progress.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('Where shall we spot today?', style: t.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Expanded(child: _IslandMap(progress: progress)),
        const SizedBox(height: 10),
        _CurrentPackCard(progress: progress),
        if (!progress.hasFamilyPass) ...[
          const SizedBox(height: 10),
          SpotCard(
            color: SpotColors.accentSoft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onTap: () => offerFamilyPass(context),
            child: Row(children: [
              const Icon(Icons.family_restroom_rounded, color: SpotColors.accent, size: 30),
              const SizedBox(width: 12),
              Expanded(child: Text('Family pass: every pack for $familyPassPrice', style: t.titleMedium)),
              const Icon(Icons.chevron_right_rounded, color: SpotColors.accent),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _IslandMap extends StatelessWidget {
  const _IslandMap({required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final stop = math.min(96.0, math.min(w * 0.26, h * 0.26));
      final current = progress.currentPack;
      Offset at(SpotPack p) => Offset(p.mapPosition.dx * w, p.mapPosition.dy * h);
      final bertie = at(current);
      final onRight = current.mapPosition.dx > 0.5;
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _MapPainter([for (final p in allPacks) p.mapPosition]))),
          for (final p in allPacks)
            Positioned(
              left: at(p).dx - stop / 2,
              top: at(p).dy - stop * 0.55,
              child: _Stop(pack: p, size: stop, progress: progress),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            left: (onRight ? bertie.dx - stop * 1.6 : bertie.dx + stop * 0.6).clamp(0, w - stop),
            top: (bertie.dy - stop * 0.35).clamp(0, h - stop),
            child: IgnorePointer(child: FlyingBertie(size: stop)),
          ),
        ]),
      );
    });
  }
}

class _Stop extends StatelessWidget {
  const _Stop({required this.pack, required this.size, required this.progress});

  final SpotPack pack;
  final double size;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final open = progress.isOpen(pack);
    final (label, color) = pack.comingSoon
        ? ('SOON', SpotColors.locked)
        : pack.free
            ? ('FREE', SpotColors.green)
            : open
                ? ('OPEN', SpotColors.green)
                : (pack.price, SpotColors.primary);
    final medal = progress.medalIn(pack);
    return Semantics(
      button: true,
      label: '${pack.name}${pack.comingSoon ? ', coming soon' : open ? '' : ', locked, ${pack.price}'}',
      child: GestureDetector(
        onTap: () => HomeScreen.openPack(context, pack),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          HexBadge(
            style: medal == null ? (open ? HexStyle.purple : HexStyle.locked) : HexStyle.values.byName(medal.name),
            size: size,
            locked: !open,
            label: label,
            labelColor: color,
            child: pack.icon.isEmpty ? const Icon(Icons.beach_access_rounded, color: SpotColors.locked, size: 40) : Image.asset(pack.icon),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: spotShadow),
            child: Text(pack.name, style: const TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w800, fontSize: 13, color: SpotColors.ink)),
          ),
        ]),
      ),
    );
  }
}

/// Sea, islands and a dotted flight path between the stops.
class _MapPainter extends CustomPainter {
  _MapPainter(this.stops);

  final List<Offset> stops;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9ED8F5), SpotColors.water]).createShader(rect));
    // Gentle wave marks.
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final o = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      canvas.drawArc(Rect.fromCenter(center: o, width: 18, height: 8), math.pi, math.pi, false, wave);
      canvas.drawArc(Rect.fromCenter(center: o + const Offset(16, 0), width: 18, height: 8), math.pi, math.pi, false, wave);
    }
    final pts = [for (final s in stops) Offset(s.dx * size.width, s.dy * size.height)];
    final r = math.min(size.width, size.height) * 0.19;
    for (final p in pts) {
      final island = Rect.fromCenter(center: p + Offset(0, r * 0.25), width: r * 2.3, height: r * 1.35);
      canvas.drawOval(island.inflate(6), Paint()..color = const Color(0xFFBFE9F7));
      canvas.drawOval(island.shift(const Offset(0, 6)), Paint()..color = const Color(0xFFD9B77A));
      canvas.drawOval(island, Paint()..color = const Color(0xFFF2D99A));
      canvas.drawOval(island.deflate(r * 0.16).shift(Offset(0, -r * 0.05)), Paint()..color = SpotColors.grass);
    }
    final dash = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i + 1 < pts.length; i++) {
      final a = pts[i], b = pts[i + 1];
      final ctrl = Offset((a.dx + b.dx) / 2 + (i.isEven ? 40 : -40), (a.dy + b.dy) / 2);
      for (var s = 0.18; s < 0.84; s += 0.06) {
        final p = _quad(a, ctrl, b, s);
        canvas.drawCircle(p, 2.6, dash);
      }
    }
  }

  static Offset _quad(Offset a, Offset c, Offset b, double t) => a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

  @override
  bool shouldRepaint(_MapPainter old) => false;
}

class _CurrentPackCard extends StatelessWidget {
  const _CurrentPackCard({required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final pack = progress.currentPack;
    final t = Theme.of(context).textTheme;
    final found = progress.foundCount(pack);
    return SpotCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        HexBadge(style: HexStyle.purple, size: 60, child: Image.asset(pack.icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pack.name, style: t.titleLarge),
            const SizedBox(height: 2),
            Text('$found of ${pack.items.length} spotted · ${progress.pointsIn(pack)} pts', style: t.bodyMedium),
          ]),
        ),
        FilledButton.icon(
          onPressed: () => HomeScreen.openPack(context, pack),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Play'),
        ),
      ]),
    );
  }
}

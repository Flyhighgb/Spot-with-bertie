import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Fill colours for the hexagon badges.
enum HexStyle {
  purple([Color(0xFFC9A9F5), Color(0xFF8D62DC)]),
  locked([Color(0xFFF2F2F7), Color(0xFFC9CDD8)]),
  bronze([Color(0xFFF3C08A), Color(0xFFB8672E)]),
  silver([Color(0xFFEEF2F8), Color(0xFF9AA6BB)]),
  gold([Color(0xFFFFE08A), Color(0xFFE8A218)]);

  const HexStyle(this.colors);
  final List<Color> colors;
}

/// A raised, glossy hexagon with a picture inside, as used on the map and for badges.
class HexBadge extends StatelessWidget {
  const HexBadge({super.key, required this.style, this.child, this.size = 88, this.locked = false, this.label, this.labelColor = SpotColors.primary});

  final HexStyle style;
  final Widget? child;
  final double size;
  final bool locked;
  final String? label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _HexPainter(style.colors))),
          if (child != null)
            Padding(
              padding: EdgeInsets.all(size * 0.22),
              child: Opacity(opacity: locked ? 0.55 : 1, child: child),
            ),
          if (locked)
            Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), shape: BoxShape.circle, boxShadow: spotShadow),
              child: Icon(Icons.lock_rounded, size: size * 0.2, color: SpotColors.inkSoft),
            ),
          if (label != null)
            Positioned(
              right: size * 0.02,
              bottom: size * 0.16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: labelColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white, width: 1.5)),
                child: Text(label!, style: TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w800, fontSize: size * 0.12, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter(this.colors);

  final List<Color> colors;

  Path _hex(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3 + math.pi / 2;
      final pt = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 * 0.98;
    final c = Offset(size.width / 2, size.height / 2 - size.height * 0.03);
    // Raised edge and soft shadow give the 3D look.
    canvas.drawPath(_hex(c + Offset(0, r * 0.14), r), Paint()..color = const Color(0x334B3278)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawPath(_hex(c + Offset(0, r * 0.08), r), Paint()..color = Color.lerp(colors[1], Colors.black, .25)!);
    canvas.drawPath(_hex(c, r), Paint()..color = Colors.white);
    final inner = _hex(c, r * 0.86);
    canvas.drawPath(inner, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors).createShader(Rect.fromCircle(center: c, radius: r)));
    canvas.drawPath(_hex(c, r * 0.70), Paint()..color = Colors.white.withValues(alpha: .88));
    // Gloss highlight on the top half.
    canvas.save();
    canvas.clipPath(inner);
    canvas.drawOval(Rect.fromCenter(center: c - Offset(r * .2, r * .55), width: r * 1.1, height: r * .5), Paint()..color = Colors.white.withValues(alpha: .35));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.colors != colors;
}

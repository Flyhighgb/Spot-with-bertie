import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// Something a child can spot, such as a suitcase or a heron.
@immutable
class SpotItem {
  const SpotItem({
    required this.id,
    required this.name,
    required this.points,
    required this.fact,
    required this.image,
  });

  final String id;
  final String name;

  /// 5 easy, 10 medium, 25 rare, 50 super rare.
  final int points;
  final String fact;
  final String image;
}

/// A place to go spotting, shown as an island on the map.
@immutable
class SpotPack {
  const SpotPack({
    required this.id,
    required this.name,
    required this.place,
    required this.icon,
    required this.items,
    required this.mapPosition,
    this.free = false,
    this.comingSoon = false,
    this.price = '99p',
    this.blurb = '',
  });

  final String id;
  final String name;

  /// Short noun used in sentences: "at the [place]".
  final String place;
  final String icon;
  final List<SpotItem> items;

  /// Where the stop sits on the map, as fractions of its width and height.
  final Offset mapPosition;
  final bool free;
  final bool comingSoon;
  final String price;
  final String blurb;

  int get totalPoints => items.fold(0, (sum, i) => sum + i.points);

  SpotItem item(String id) => items.firstWhere((i) => i.id == id);

  /// One item a day is worth double. It changes at midnight.
  SpotItem goldenFor(DateTime day) {
    final dayOfYear = day.difference(DateTime(day.year)).inDays + 1;
    return items[(day.year * 1000 + dayOfYear) % items.length];
  }
}

/// Badges a child earns in each pack.
enum Medal {
  bronze('Bronze', 50, 'Bronze Spotter', 'You have sharp eyes!'),
  silver('Silver', 125, 'Silver Spotter', 'You spot things others miss.'),
  gold('Gold', 200, 'Gold Spotter', 'A true spotting expert!');

  const Medal(this.label, this.points, this.title, this.blurb);

  final String label;
  final int points;
  final String title;
  final String blurb;

  /// The best medal for a score, or null below bronze.
  static Medal? forPoints(int points) {
    Medal? best;
    for (final m in Medal.values) {
      if (points >= m.points) best = m;
    }
    return best;
  }

  /// The next medal to aim for, or null once gold is reached.
  static Medal? nextAfter(int points) {
    for (final m in Medal.values) {
      if (points < m.points) return m;
    }
    return null;
  }
}

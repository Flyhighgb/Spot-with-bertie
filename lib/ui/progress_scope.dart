import 'package:flutter/widgets.dart';

import '../data/progress.dart';
import '../services/purchases.dart';

/// Makes the child's [Progress] and the shop available to every screen,
/// and rebuilds them when progress changes.
class ProgressScope extends InheritedNotifier<Progress> {
  const ProgressScope({super.key, required Progress progress, required this.purchases, required super.child}) : super(notifier: progress);

  final Purchases purchases;

  static Progress of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ProgressScope>()!.notifier!;

  static Purchases purchasesOf(BuildContext context) => context.getInheritedWidgetOfExactType<ProgressScope>()!.purchases;
}

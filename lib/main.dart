import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/progress.dart';
import 'services/purchases.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final progress = await Progress.open();
  runApp(SpotApp(progress: progress, purchases: PretendPurchases(progress)));
}

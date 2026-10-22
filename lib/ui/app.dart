import 'package:flutter/material.dart';

import '../data/progress.dart';
import '../services/purchases.dart';
import 'progress_scope.dart';
import 'screens/album_screen.dart';
import 'screens/badges_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

class SpotApp extends StatelessWidget {
  const SpotApp({super.key, required this.progress, required this.purchases});

  final Progress progress;
  final Purchases purchases;

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      progress: progress,
      purchases: purchases,
      child: MaterialApp(
        title: 'Spot with Bertie',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AppShell(),
      ),
    );
  }
}

/// The three tabs: the map, the sticker album and the badges.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [SpotColors.sky1, SpotColors.sky2]),
        ),
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _tab, children: const [HomeScreen(), AlbumScreen(), BadgesScreen()]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: SpotColors.accentSoft,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded, color: SpotColors.accent), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark_rounded, color: SpotColors.accent), label: 'Stickers'),
          NavigationDestination(icon: Icon(Icons.military_tech_outlined), selectedIcon: Icon(Icons.military_tech_rounded, color: SpotColors.accent), label: 'Badges'),
        ],
      ),
    );
  }
}

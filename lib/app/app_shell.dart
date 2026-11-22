import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:six_on_six/core/ui/motion.dart';

/// The bottom navigation bar, for the first-run tip that points at it.
final GlobalKey navBarKey = GlobalKey(debugLabel: 'nav bar');

/// The main app frame: the five tabs and the bottom navigation bar.
/// Lessons open above this frame, so the bar is hidden while playing.
class AppShell extends StatelessWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabFade(index: shell.currentIndex, child: shell),
      bottomNavigationBar: KeyedSubtree(
        key: navBarKey,
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(
            index,
            // Tapping the current tab again returns to its first screen.
            initialLocation: index == shell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Learn',
            ),
            NavigationDestination(
              icon: Icon(Icons.redeem_outlined),
              selectedIcon: Icon(Icons.redeem),
              label: 'Quests',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: 'League',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Glossary',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

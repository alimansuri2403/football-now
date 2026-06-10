import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class NavigationShell extends ConsumerWidget {
  final Widget child;
  final GoRouterState state;

  const NavigationShell({
    super.key,
    required this.child,
    required this.state,
  });

  int _getSelectedIndex(String location) {
    if (location.startsWith('/teams')) return 1;
    if (location.startsWith('/players')) return 2;
    return 0; // Home is default
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/teams');
        break;
      case 2:
        context.go('/players');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = state.uri.path;
    final selectedIndex = _getSelectedIndex(location);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, size: 28, color: Colors.amber),
            const SizedBox(width: 10),
            Text(
              'FIFA 2026 WORLD CUP',
              style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.amber,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;

          if (isWide) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  leading: Column(
                    children: [
                      const SizedBox(height: 20),
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/b/b4/FIFA_logo_%282010%29.svg',
                        height: 30,
                        width: 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(height: 30),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.sports_soccer_outlined),
                      selectedIcon: Icon(Icons.sports_soccer, color: Colors.amber),
                      label: Text('Scoreboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.table_chart_outlined),
                      selectedIcon: Icon(Icons.table_chart, color: Colors.amber),
                      label: Text('Standings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_alt_outlined),
                      selectedIcon: Icon(Icons.people_alt, color: Colors.amber),
                      label: Text('Stats & Players'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: child),
              ],
            );
          }

          return child;
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 768
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) => _onItemTapped(index, context),
              selectedItemColor: Colors.amber,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_soccer_outlined),
                  activeIcon: Icon(Icons.sports_soccer),
                  label: 'Scoreboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.table_chart_outlined),
                  activeIcon: Icon(Icons.table_chart),
                  label: 'Standings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt_outlined),
                  activeIcon: Icon(Icons.people_alt),
                  label: 'Stats & Players',
                ),
              ],
            )
          : null,
    );
  }
}

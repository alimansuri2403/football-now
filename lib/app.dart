import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'widgets/nav_shell.dart';
import 'screens/home_screen.dart';
import 'screens/live_matches_screen.dart';
import 'screens/standings_screen.dart';
import 'screens/match_detail_screen.dart';
import 'screens/teams_screen.dart';
import 'screens/team_detail_screen.dart';
import 'screens/players_screen.dart';
import 'screens/player_detail_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// Declare GoRouter outside the build method (or via Provider) to prevent re-creation and duplicate GlobalKeys.
// We omit explicit navigator keys for branches to let GoRouter manage them dynamically, avoiding key conflicts.
final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) {
        return NavShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'match/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return MatchDetailScreen(matchId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 2: Live Matches
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/live',
              builder: (context, state) => const LiveMatchesScreen(),
            ),
          ],
        ),
        // Branch 3: Standings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/standings',
              builder: (context, state) => const StandingsScreen(),
            ),
          ],
        ),
        // Branch 4: Teams
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/teams',
              builder: (context, state) => const TeamsScreen(),
              routes: [
                GoRoute(
                  path: 'team/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return TeamDetailScreen(teamId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 5: Player Leaderboards
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/players',
              builder: (context, state) => const PlayersScreen(),
              routes: [
                GoRoute(
                  path: 'player/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return PlayerDetailScreen(playerId: id);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FIFA 2026 Scoreboard & Stats',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

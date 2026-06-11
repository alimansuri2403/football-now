import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/support_team_provider.dart';
import 'widgets/nav_shell.dart';
import 'screens/home_screen.dart';
import 'screens/live_matches_screen.dart';
import 'screens/standings_screen.dart';
import 'screens/match_detail_screen.dart';
import 'screens/teams_screen.dart';
import 'screens/team_detail_screen.dart';
import 'screens/players_screen.dart';
import 'screens/player_detail_screen.dart';
import 'screens/bracket_screen.dart';
import 'screens/prediction_screen.dart';
import 'screens/bracket_simulator_screen.dart';
import 'screens/power_rankings_screen.dart';
import 'screens/fan_challenges_screen.dart';
import 'screens/fan_chat_screen.dart';
import 'screens/stadium_explorer_screen.dart';
import 'screens/fantasy_screen.dart';
import 'screens/wc_journey_screen.dart';
import 'screens/player_comparison_screen.dart';
import 'screens/support_team_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

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
        // Branch 6: Knockout Bracket
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bracket',
              builder: (context, state) => const BracketScreen(),
            ),
          ],
        ),
      ],
    ),
    
    // Add additional features as root-level routes for easy navigation
    GoRoute(
      path: '/prediction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PredictionScreen(),
    ),
    GoRoute(
      path: '/bracket-simulator',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BracketSimulatorScreen(),
    ),
    GoRoute(
      path: '/power-rankings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PowerRankingsScreen(),
    ),
    GoRoute(
      path: '/challenges',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FanChallengesScreen(),
    ),
    GoRoute(
      path: '/stadiums',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StadiumExplorerScreen(),
    ),
    GoRoute(
      path: '/fantasy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FantasyScreen(),
    ),
    GoRoute(
      path: '/journey',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WcJourneyScreen(),
    ),
    GoRoute(
      path: '/comparison',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PlayerComparisonScreen(),
    ),
    GoRoute(
      path: '/chat/:id/:title',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final title = state.pathParameters['title'] ?? '';
        return FanChatScreen(matchId: id, matchTitle: title);
      },
    ),
    GoRoute(
      path: '/support',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SupportTeamScreen(),
    ),
  ],
);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    // Watch support team color to update app primary color dynamically
    ref.watch(supportTeamProvider);
    final supportTeamNotifier = ref.read(supportTeamProvider.notifier);
    final primaryColor = supportTeamNotifier.teamColor;

    return MaterialApp.router(
      title: 'FIFA 2026 Scoreboard & Stats',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeWithColor(primaryColor),
      darkTheme: AppTheme.darkThemeWithColor(primaryColor),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

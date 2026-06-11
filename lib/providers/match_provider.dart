import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';
import '../services/espn_api.dart';
import '../services/notification_service.dart';
import '../data/repository.dart';

// ── ESPN API provider (free, no key — same source as claudinho) ───────────────
final espnApiProvider = Provider<EspnApiService>((ref) => EspnApiService());

// ── Repository for teams/players mock data ────────────────────────────────────
final repositoryProvider = Provider<DataRepository>((ref) {
  final repo = MockDataRepository(
    getMatches: () => ref.read(matchProvider).allMatches,
    espnApi: ref.watch(espnApiProvider),
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

// ── Match detail by ID ─────────────────────────────────────────────────────────
final matchDetailProvider = FutureProvider.family<Match?, String>((ref, id) async {
  final state = ref.watch(matchProvider);
  try {
    return state.allMatches.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

// ── Main match state provider ──────────────────────────────────────────────────
final matchProvider =
    StateNotifierProvider<MatchNotifier, MatchState>((ref) {
  final espn = ref.watch(espnApiProvider);
  final notifier = MatchNotifier(espn);
  ref.onDispose(() => notifier.disposeNotifier());
  return notifier;
});

// ── State ──────────────────────────────────────────────────────────────────────
class MatchState {
  final List<Match> allMatches;
  final List<Match> liveMatches;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  MatchState({
    required this.allMatches,
    required this.liveMatches,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  MatchState copyWith({
    List<Match>? allMatches,
    List<Match>? liveMatches,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return MatchState(
      allMatches: allMatches ?? this.allMatches,
      liveMatches: liveMatches ?? this.liveMatches,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class MatchNotifier extends StateNotifier<MatchState> {
  final EspnApiService _espn;
  Timer? _liveTimer;   // Every 30s — live score refresh
  Timer? _allTimer;    // Every 5min — full schedule refresh

  MatchNotifier(this._espn)
      : super(MatchState(allMatches: [], liveMatches: [], isLoading: true)) {
    // 1. Fetch full schedule on start
    fetchMatches();

    // 2. Refresh live scores every 30 seconds
    _liveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshLiveScores();
    });

    // 3. Refresh full schedule every 5 minutes
    _allTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchMatches();
    });
  }

  /// Full schedule fetch — called on startup and pull-to-refresh.
  Future<void> fetchMatches() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Fetch entire tournament schedule (all 104 matches, June 11 – July 19)
      final allFixtures = await _espn.fetchAllFixtures();

      // Also get today's scoreboard to overlay live data
      final scoreboard = await _espn.fetchScoreboard();

      // Merge: fixture list is the base, today's live data overlays it
      final Map<String, Match> merged = {
        for (final m in allFixtures) m.id: m,
      };
      for (final m in scoreboard) {
        merged[m.id] = m; // live data wins
      }

      final all = merged.values.toList()
        ..sort((a, b) => a.kickoffTime.compareTo(b.kickoffTime));

      final live = all
          .where((m) =>
              m.status == MatchStatus.live ||
              m.status == MatchStatus.halftime)
          .toList();

      if (!mounted) return;
      state = state.copyWith(
        allMatches: all,
        liveMatches: live,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load fixtures. Check your connection.',
      );
    }
  }

  /// Only refresh live scores (lightweight — called every 30s).
  Future<void> _refreshLiveScores() async {
    if (!mounted) return;
    try {
      final scoreboard = await _espn.fetchScoreboard();
      final live = scoreboard
          .where((m) =>
              m.status == MatchStatus.live ||
              m.status == MatchStatus.halftime)
          .toList();

      // Detect newly live matches and fire notifications
      final previousLiveIds = state.liveMatches.map((m) => m.id).toSet();
      for (final m in live) {
        if (!previousLiveIds.contains(m.id)) {
          NotificationService().showMatchLiveNotification(m);
        }
      }

      // Merge: keep all existing matches but update any that appear in scoreboard
      final Map<String, Match> existing = {
        for (final m in state.allMatches) m.id: m
      };
      for (final m in scoreboard) {
        existing[m.id] = m;
      }

      if (!mounted) return;
      state = state.copyWith(
        allMatches: existing.values.toList(),
        liveMatches: live,
        lastUpdated: DateTime.now(),
      );
    } catch (_) {
      // Silent fail on live refresh — don't show error for background updates
    }
  }

  void disposeNotifier() {
    _liveTimer?.cancel();
    _allTimer?.cancel();
  }
}

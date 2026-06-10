import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';
import '../services/football_api.dart';
import '../data/repository.dart';

// Provide the single source of FootballApiService
final apiServiceProvider = Provider<FootballApiService>((ref) {
  return FootballApiService();
});

// Provide the single source of repository
final repositoryProvider = Provider<DataRepository>((ref) {
  final repo = MockDataRepository();
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

// Get a single match by id (using FootballApiService)
final matchDetailProvider = FutureProvider.family<Match?, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchMatchDetails(id);
});

// Match state provider that updates matches periodically
final matchProvider = StateNotifierProvider<MatchNotifier, MatchState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = MatchNotifier(apiService);
  ref.onDispose(() {
    notifier.disposeNotifier();
  });
  return notifier;
});

class MatchState {
  final List<Match> allMatches;
  final List<Match> liveMatches;
  final bool isLoading;
  final String? errorMessage;

  MatchState({
    required this.allMatches,
    required this.liveMatches,
    this.isLoading = false,
    this.errorMessage,
  });

  MatchState copyWith({
    List<Match>? allMatches,
    List<Match>? liveMatches,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MatchState(
      allMatches: allMatches ?? this.allMatches,
      liveMatches: liveMatches ?? this.liveMatches,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MatchNotifier extends StateNotifier<MatchState> {
  final FootballApiService _apiService;
  Timer? _refreshTimer;

  MatchNotifier(this._apiService) : super(MatchState(allMatches: [], liveMatches: [], isLoading: true)) {
    // Initial fetch of data
    fetchMatches();
    
    // Set up periodic timer to refresh matches every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchMatches();
    });
  }

  Future<void> fetchMatches() async {
    try {
      final matches = await _apiService.fetchFixtures();
      final live = await _apiService.fetchLiveMatches();
      state = state.copyWith(
        allMatches: matches,
        liveMatches: live,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load fixtures: $e',
      );
    }
  }

  void disposeNotifier() {
    _refreshTimer?.cancel();
  }
}

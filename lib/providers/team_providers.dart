import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import 'match_provider.dart';

final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getTeams();
});

final teamDetailProvider = FutureProvider.family<Team?, String>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getTeamById(id);
});

// Standings calculations by group name
final groupStandingsProvider = FutureProvider.family<List<GroupStanding>, String>((ref, group) async {
  final apiService = ref.watch(apiServiceProvider);
  // Re-run whenever match state updates (periodic polling updates scores and triggers this)
  ref.watch(matchProvider);
  return apiService.fetchStandings(group);
});

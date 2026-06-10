import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import 'match_provider.dart';

final playersProvider = FutureProvider<List<Player>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getPlayers();
});

final playerDetailProvider = FutureProvider.family<Player?, String>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getPlayerById(id);
});

final teamPlayersProvider = FutureProvider.family<List<Player>, String>((ref, teamId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getPlayersByTeam(teamId);
});

final topScorersProvider = FutureProvider<List<Player>>((ref) async {
  final players = await ref.watch(playersProvider.future);
  final sorted = List<Player>.from(players);
  sorted.sort((a, b) => b.stats.goals.compareTo(a.stats.goals));
  return sorted;
});

final topAssistsProvider = FutureProvider<List<Player>>((ref) async {
  final players = await ref.watch(playersProvider.future);
  final sorted = List<Player>.from(players);
  sorted.sort((a, b) => b.stats.assists.compareTo(a.stats.assists));
  return sorted;
});

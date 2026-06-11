import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFavKey = 'favourite_teams';

final favouritesProvider =
    StateNotifierProvider<FavouritesNotifier, Set<String>>((ref) {
  return FavouritesNotifier();
});

class FavouritesNotifier extends StateNotifier<Set<String>> {
  FavouritesNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_kFavKey) ?? [];
      state = saved.toSet();
    } catch (_) {}
  }

  Future<void> toggleFavourite(String teamCode) async {
    final code = teamCode.toUpperCase();
    final next = Set<String>.from(state);
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFavKey, next.toList());
    } catch (_) {}
  }

  bool isFavourite(String teamCode) => state.contains(teamCode.toUpperCase());
}

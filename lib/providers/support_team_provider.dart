import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

const _kSupportKey = 'support_team';

// Map of team codes to their brand colors
const Map<String, Color> teamColors = {
  'ARG': Color(0xFF74ACDF), // Argentina sky blue
  'BRA': Color(0xFFFFD700), // Brazil gold
  'FRA': Color(0xFF0055A4), // France blue
  'ENG': Color(0xFFCF081F), // England red
  'GER': Color(0xFF000000), // Germany black
  'ESP': Color(0xFFAA151B), // Spain red
  'POR': Color(0xFF006600), // Portugal green
  'NED': Color(0xFFFF6600), // Netherlands orange
  'BEL': Color(0xFFEF3340), // Belgium red
  'URU': Color(0xFF5EB6E4), // Uruguay sky blue
  'USA': Color(0xFF002868), // USA navy
  'MEX': Color(0xFF006847), // Mexico green
  'CAN': Color(0xFFFF0000), // Canada red
  'JPN': Color(0xFF003087), // Japan navy
  'KOR': Color(0xFF003478), // Korea navy
  'AUS': Color(0xFF00843D), // Australia green
  'MAR': Color(0xFFC1272D), // Morocco red
  'SEN': Color(0xFF00853F), // Senegal green
  'EGY': Color(0xFFCC0001), // Egypt red
  'SAU': Color(0xFF006C35), // Saudi green
  'IRN': Color(0xFF239F40), // Iran green
  'SUI': Color(0xFFFF0000), // Swiss red
  'NOR': Color(0xFFEF2B2D), // Norway red
  'SWE': Color(0xFF006AA7), // Sweden blue
  'CRO': Color(0xFFFF0000), // Croatia red/checkered
  'GHA': Color(0xFF006B3F), // Ghana green
  'SCO': Color(0xFF003087), // Scotland navy
};

final supportTeamProvider = StateNotifierProvider<SupportTeamNotifier, String?>((ref) {
  return SupportTeamNotifier();
});

class SupportTeamNotifier extends StateNotifier<String?> {
  SupportTeamNotifier() : super(null) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kSupportKey);
  }

  Future<void> selectTeam(String teamCode) async {
    state = teamCode.toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSupportKey, state!);
  }

  Future<void> clearTeam() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSupportKey);
  }

  Color get teamColor {
    if (state == null) return const Color(0xFF00E5FF); // default cyan
    return teamColors[state] ?? const Color(0xFF00E5FF);
  }
}

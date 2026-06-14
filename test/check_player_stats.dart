import 'package:flutter_test/flutter_test.dart';
import 'package:fifa2026_app/data/repository.dart';
import 'package:fifa2026_app/models/models.dart';

void main() {
  test('Check Player Stats Distribution', () async {
    final repo = MockDataRepository();
    final teams = await repo.getTeams();
    
    print('Checking stats for all teams...');
    int totalFWD = 0;
    int totalMID = 0;
    int totalDEF = 0;
    int totalGK = 0;
    
    double sumGoalsFWD = 0;
    double sumGoalsMID = 0;
    double sumGoalsDEF = 0;
    
    for (var team in teams) {
      final players = await repo.getPlayersByTeam(team.code);
      for (var p in players) {
        final stats = p.stats;
        if (p.position == 'Forward' || p.position == 'FWD') {
          totalFWD++;
          sumGoalsFWD += stats.goals;
        } else if (p.position == 'Midfielder' || p.position == 'MID') {
          totalMID++;
          sumGoalsMID += stats.goals;
        } else if (p.position == 'Defender' || p.position == 'DEF') {
          totalDEF++;
          sumGoalsDEF += stats.goals;
        } else if (p.position == 'Goalkeeper' || p.position == 'GK') {
          totalGK++;
        }
      }
    }
    
    print('FWDs count: $totalFWD, average goals: ${totalFWD > 0 ? (sumGoalsFWD / totalFWD).toStringAsFixed(2) : 0}');
    print('MIDs count: $totalMID, average goals: ${totalMID > 0 ? (sumGoalsMID / totalMID).toStringAsFixed(2) : 0}');
    print('DEFs count: $totalDEF, average goals: ${totalDEF > 0 ? (sumGoalsDEF / totalDEF).toStringAsFixed(2) : 0}');
    
    // Let's print some star players
    final players = await repo.getPlayersByTeam('ARG');
    print('\nStar Player details for ARG:');
    for (var p in players) {
      if (p.name.toLowerCase().contains('messi')) {
        print('${p.name}: Position=${p.position}, Rating=${p.rating}, Goals=${p.stats.goals}, Assists=${p.stats.assists}, Matches=${p.stats.matchesPlayed}, Mins=${p.stats.minutesPlayed}, Yellow=${p.stats.yellowCards}, Red=${p.stats.redCards}');
      }
    }
    
    final porPlayers = await repo.getPlayersByTeam('POR');
    print('\nStar Player details for POR:');
    for (var p in porPlayers) {
      if (p.name.toLowerCase().contains('ronaldo')) {
        print('${p.name}: Position=${p.position}, Rating=${p.rating}, Goals=${p.stats.goals}, Assists=${p.stats.assists}, Matches=${p.stats.matchesPlayed}, Mins=${p.stats.minutesPlayed}, Yellow=${p.stats.yellowCards}, Red=${p.stats.redCards}');
      }
    }
    
    final fraPlayers = await repo.getPlayersByTeam('FRA');
    print('\nStar Player details for FRA:');
    for (var p in fraPlayers) {
      if (p.name.toLowerCase().contains('mbapp') || p.name.toLowerCase().contains('mbappe')) {
        print('${p.name}: Position=${p.position}, Rating=${p.rating}, Goals=${p.stats.goals}, Assists=${p.stats.assists}, Matches=${p.stats.matchesPlayed}, Mins=${p.stats.minutesPlayed}, Yellow=${p.stats.yellowCards}, Red=${p.stats.redCards}');
      }
    }
  });
}

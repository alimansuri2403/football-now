import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/support_team_provider.dart';
import '../providers/team_providers.dart';
import '../models/team.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class SupportTeamScreen extends ConsumerWidget {
  const SupportTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final selectedTeamCode = ref.watch(supportTeamProvider);
    final teamsAsync = ref.watch(teamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Support Mode'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TEAM SUPPORT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select Your Team',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Show your colors! Selecting a favorite team changes the entire app color palette to their official team colors.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Active support banner
            if (selectedTeamCode != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        AppConstants.getFlagUrl(_getFlagCode(selectedTeamCode)),
                        width: 48,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOU ARE SUPPORTING',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            selectedTeamCode,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        ref.read(supportTeamProvider.notifier).clearTeam();
                      },
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Teams list
            Expanded(
              child: teamsAsync.when(
                data: (teams) {
                  // Filter to only those teams that have colors defined in teamColors
                  final coloredTeams = teams.where((t) => teamColors.containsKey(t.code)).toList();

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: coloredTeams.length,
                    itemBuilder: (context, index) {
                      final team = coloredTeams[index];
                      final isSelected = team.code == selectedTeamCode;
                      final primaryColor = teamColors[team.code] ?? theme.colorScheme.primary;

                      return GestureDetector(
                        onTap: () {
                          ref.read(supportTeamProvider.notifier).selectTeam(team.code);
                        },
                        child: AnimatedContainer(
                          duration: AppConstants.shortAnimation,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? primaryColor.withOpacity(0.15) 
                                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey.withOpacity(0.15),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.network(
                                  AppConstants.getFlagUrl(team.flagCode),
                                  width: 40,
                                  height: 27,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.flag),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                team.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected ? primaryColor : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Colored dot representing team theme color
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFlagCode(String teamCode) {
    // Basic codes fallback mapping
    final Map<String, String> map = {
      'ARG': 'ar', 'BRA': 'br', 'FRA': 'fr', 'ENG': 'gb-eng', 'GER': 'de',
      'ESP': 'es', 'POR': 'pt', 'NED': 'nl', 'BEL': 'be', 'URU': 'uy',
      'USA': 'us', 'MEX': 'mx', 'CAN': 'ca', 'JPN': 'jp', 'KOR': 'kr',
      'AUS': 'au', 'MAR': 'ma', 'SEN': 'sn', 'EGY': 'eg', 'SAU': 'sa',
      'IRN': 'ir', 'SUI': 'ch', 'NOR': 'no', 'SWE': 'se', 'CRO': 'hr',
      'GHA': 'gh', 'SCO': 'gb-sct',
    };
    return map[teamCode] ?? teamCode.substring(0, 2).toLowerCase();
  }
}

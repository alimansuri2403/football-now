import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/wc2026_data.dart';
import '../models/match.dart';
import '../providers/match_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class StadiumExplorerScreen extends ConsumerStatefulWidget {
  const StadiumExplorerScreen({super.key});

  @override
  ConsumerState<StadiumExplorerScreen> createState() => _StadiumExplorerScreenState();
}

class _StadiumExplorerScreenState extends ConsumerState<StadiumExplorerScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matchState = ref.watch(matchProvider);

    final filteredStadiums = WC2026Data.stadiums.where((stadium) {
      final query = _searchQuery.toLowerCase();
      return stadium.name.toLowerCase().contains(query) ||
          stadium.city.toLowerCase().contains(query) ||
          stadium.country.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stadium Explorer'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STADIUMS',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Host Cities & Venues',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search stadiums or host cities...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Stadiums Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredStadiums.length,
                itemBuilder: (context, index) {
                  final stadium = filteredStadiums[index];
                  return _StadiumCard(
                    stadium: stadium,
                    theme: theme,
                    isDark: isDark,
                    onTap: () => _showStadiumDetails(context, stadium, matchState.allMatches),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStadiumDetails(BuildContext context, WC2026Stadium stadium, List<Match> allMatches) {
    // Filter matches scheduled at this stadium
    final scheduledMatches = allMatches.where((m) {
      final venueStr = m.venue.toLowerCase();
      final cityStr = m.city?.toLowerCase() ?? '';
      final stadiumName = stadium.name.toLowerCase();
      final stadiumCity = stadium.city.toLowerCase();
      return venueStr.contains(stadiumName) || 
             stadiumName.contains(venueStr) || 
             cityStr.contains(stadiumCity) || 
             stadiumCity.contains(cityStr);
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBg : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Header
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: Image.network(
                      stadium.imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: Colors.grey.withOpacity(0.2),
                        child: const Icon(Icons.stadium, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stadium.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Details Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              Icons.location_city,
                              'City',
                              stadium.city,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              Icons.people,
                              'Capacity',
                              NumberFormat('#,###').format(stadium.capacity),
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              Icons.grass,
                              'Surface',
                              stadium.surface,
                              theme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              Icons.public,
                              'Country',
                              stadium.country,
                              theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Schedule Heading
                      Text(
                        'Scheduled Matches',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      if (scheduledMatches.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No matches scheduled at this venue.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: scheduledMatches.length,
                          itemBuilder: (context, idx) {
                            final match = scheduledMatches[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? Colors.white10 : Colors.black12,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('MMM d').format(match.kickoffTime),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('h:mm a').format(match.kickoffTime),
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(match.homeTeam.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Text('vs', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text(match.awayTeam.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                subtitle: Text(
                                  match.stage ?? (match.group != null ? 'Group ${match.group}' : ''),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 16),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  // Nav to match
                                  // Since we might be nested, we can just push on root navigator
                                  // E.g. context.push('/match/${match.id}')
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glassDecoration(context: context, radius: 16),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StadiumCard extends StatelessWidget {
  final WC2026Stadium stadium;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onTap;

  const _StadiumCard({
    required this.stadium,
    required this.theme,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.network(
              stadium.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.withOpacity(0.1),
                child: const Icon(Icons.stadium, color: Colors.grey, size: 48),
              ),
            ),

            // Bottom Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 0.95],
                ),
              ),
            ),

            // Content Overlay
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stadium.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Country Flag
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.network(
                          AppConstants.getFlagUrl(stadium.countryCode),
                          width: 20,
                          height: 14,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stadium.city,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '👤 ${NumberFormat('#,###').format(stadium.capacity)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      if (stadium.host != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stadium.host!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/match_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timezone_provider.dart';
import '../widgets/live_score_card.dart';
import '../widgets/shimmer_loading.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/match.dart';
import '../services/ad_service.dart';
import '../data/wc2026_data.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    // Tick every second for live countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _loadBannerAd() {
    if (kIsWeb) {
      setState(() { _isBannerAdLoaded = true; });
      return;
    }
    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        setState(() { _isBannerAdLoaded = true; });
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        setState(() {
          _isBannerAdLoaded = false;
          _bannerAd = null;
        });
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matchState = ref.watch(matchProvider);
    final tzState = ref.watch(timezoneProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(matchProvider.notifier).fetchMatches(),
          child: CustomScrollView(
            slivers: [
              // Header App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 54,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FIFA WORLD CUP 2026',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scoreboard & Stats',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Timezone chip + Theme Switcher
                      Row(
                        children: [
                          _TimezoneChip(tzState: tzState),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              ref.read(themeModeProvider.notifier).toggleTheme();
                            },
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Live Scores Section
              SliverToBoxAdapter(
                child: matchState.isLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ShimmerLoading(child: ShimmerLoading.scoreboardCarousel()),
                      )
                    : matchState.liveMatches.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Live Matches Now',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: matchState.liveMatches.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: LiveScoreCard(match: matchState.liveMatches[index]),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
              ),

              // Stadiums Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Host Stadiums',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: WC2026Data.stadiums.length,
                        itemBuilder: (context, index) {
                          final stadium = WC2026Data.stadiums[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 280,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        stadium.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                          child: const Icon(Icons.stadium, size: 48, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.85),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (stadium.host != null)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.amber,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                stadium.host!,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            stadium.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${stadium.city}, ${stadium.country}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Capacity: ${NumberFormat('#,###').format(stadium.capacity)}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Search Box for Schedule
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        setState(() { _searchQuery = val.toLowerCase(); });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search teams or groups...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // Schedule Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
                  child: Text(
                    'Match Schedule',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Schedule Items
              if (matchState.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: ShimmerLoading(child: ShimmerLoading.cardList(count: 4)),
                  ),
                )
              else if (matchState.errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Failed to load schedule: ${matchState.errorMessage}'),
                  ),
                )
              else
                _buildScheduleSliver(matchState.allMatches),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isBannerAdLoaded
          ? Container(
              color: theme.scaffoldBackgroundColor,
              alignment: Alignment.center,
              height: 50,
              child: kIsWeb
                  ? Container(
                      width: 320,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Ad',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AdMob Banner Ad (Web Simulator)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : (_bannerAd != null ? AdWidget(ad: _bannerAd!) : const SizedBox.shrink()),
            )
          : null,
    );
  }

  Widget _buildScheduleSliver(List<Match> allMatches) {
    final filtered = allMatches.where((match) {
      final query = _searchQuery;
      if (query.isEmpty) return true;
      return match.homeTeam.name.toLowerCase().contains(query) ||
          match.awayTeam.name.toLowerCase().contains(query) ||
          (match.group ?? "").toLowerCase().contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No matches match your search query.'),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final match = filtered[index];
            return _buildScheduleItem(context, match);
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, Match match) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLive = match.status == MatchStatus.live;
    final isFinished = match.status == MatchStatus.finished;

    return InkWell(
      onTap: () {
        context.go('/match/${match.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            // Left: Date / Group / Countdown column
            SizedBox(
              width: 95,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    match.group != null ? 'Group ${match.group}' : (match.stage ?? ''),
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (match.status == MatchStatus.scheduled &&
                      match.kickoffTime.isAfter(_now))
                    _CountdownWidget(kickoff: match.kickoffTime, now: _now, theme: theme)
                  else
                    _LocalizedTimeText(kickoffTime: match.kickoffTime, theme: theme),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Match Teams Comparison row
            Expanded(
              child: Row(
                children: [
                  // Home flag & code
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(
                      AppConstants.getFlagUrl(match.homeTeam.flagCode),
                      width: 20,
                      height: 14,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    match.homeTeam.code,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Score / VS
                  if (isLive || isFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive ? AppTheme.liveColor.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${match.homeScore} - ${match.awayScore}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLive ? AppTheme.liveColor : null,
                        ),
                      ),
                    )
                  else
                    Text(
                      'VS',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  const Spacer(),
                  // Away code & flag
                  Text(
                    match.awayTeam.code,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(
                      AppConstants.getFlagUrl(match.awayTeam.flagCode),
                      width: 20,
                      height: 14,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Timezone chip shown in header ───────────────────────────────────────────────
class _TimezoneChip extends ConsumerWidget {
  final TimezoneState tzState;
  const _TimezoneChip({required this.tzState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('/settings'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.network(
                AppConstants.getFlagUrl(tzState.countryCode),
                width: 18,
                height: 12,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 12),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              tzState.timezoneAbbreviation,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more, size: 14, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

// ── Localized time text that rebuilds when timezone changes ─────────────────────
class _LocalizedTimeText extends ConsumerWidget {
  final DateTime kickoffTime;
  final ThemeData theme;
  const _LocalizedTimeText({required this.kickoffTime, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tzState = ref.watch(timezoneProvider);
    final tzNotifier = ref.read(timezoneProvider.notifier);
    final local = tzNotifier.convertToLocal(kickoffTime);
    return Text(
      '${DateFormat('MMM d, HH:mm').format(local)} ${tzState.timezoneAbbreviation}',
      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ── Countdown widget ────────────────────────────────────────────────────────────
class _CountdownWidget extends StatelessWidget {
  final DateTime kickoff;
  final DateTime now;
  final ThemeData theme;

  const _CountdownWidget({
    required this.kickoff,
    required this.now,
    required this.theme,
  });

  String _format(Duration d) {
    if (d.inDays >= 1) {
      return '${d.inDays}d ${d.inHours % 24}h';
    } else if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    } else if (d.inMinutes >= 1) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    }
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = kickoff.difference(now);
    if (remaining.isNegative) {
      return Text(
        'Starting soon',
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppTheme.liveColor,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '⏱ ${_format(remaining)}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/match_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/live_score_card.dart';
import '../widgets/shimmer_loading.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/match.dart';
import '../services/ad_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (kIsWeb) {
      // On web, AdMob native SDK is not available.
      // We immediately set loaded to show the web simulator banner.
      setState(() {
        _isBannerAdLoaded = true;
      });
      return;
    }
    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        setState(() {
          _isBannerAdLoaded = true;
        });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Providers
    final matchState = ref.watch(matchProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(matchProvider.notifier).fetchMatches(),
          child: CustomScrollView(
            slivers: [
              // Beautiful Header App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      // Theme Switcher
                      IconButton(
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 28,
                        ),
                      )
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
                        setState(() {
                          _searchQuery = val.toLowerCase();
                        });
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
          match.group.toLowerCase().contains(query);
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
            // Left Date column
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    match.group,
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, HH:mm').format(match.dateTime),
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
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

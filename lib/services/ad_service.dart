import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Singleton instance
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Test Ad Unit IDs (AdMob Developer Test IDs)
  static String get bannerAdUnitId {
    if (kIsWeb) {
      return ''; // Ads are not supported on web natively by google_mobile_ads
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-4191402077839605/1833930188';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-4191402077839605/9040626507';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  // Interstitial Ad tracking
  int _matchDetailOpens = 0;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;

  // Rewarded Ad tracking
  int _rewardedClicksCount = 0;
  int _rewardedClicksTarget = 3; // Initialized to 3, then randomized between 3 and 4
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  // Initialize the Mobile Ads SDK
  Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // Load Interstitial Ad in background
  void _loadInterstitialAd() {
    if (kIsWeb) return;
    if (_isInterstitialAdLoading || _interstitialAd != null) return;

    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          _setupInterstitialCallbacks(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  void _setupInterstitialCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        // Preload the next interstitial ad
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        // Preload the next interstitial ad
        _loadInterstitialAd();
      },
    );
  }

  // Track match-detail page open and show ad on every 3rd open (web demo) / 5th open (native)
  void incrementMatchDetailOpensAndShow(BuildContext context) {
    _matchDetailOpens++;
    final trigger = kIsWeb ? 3 : 5;
    debugPrint('Match detail page opened: $_matchDetailOpens / $trigger times');
    if (_matchDetailOpens % trigger == 0) {
      if (kIsWeb) {
        _showWebInterstitialDialog(context);
      } else {
        showInterstitialAd();
      }
    }
  }

  // Show Interstitial Ad immediately if loaded (Mobile only)
  void showInterstitialAd() {
    if (kIsWeb) return;
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not loaded yet, preloading...');
      _loadInterstitialAd();
    }
  }

  // Simulated Web Interstitial Dialog
  void _showWebInterstitialDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 340,
            height: 480,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xEE0A0E21) : const Color(0xEEFFFFFF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'SPONSORED (TEST)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'FIFA World Cup 2026',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This is a web simulation of the AdMob Interstitial Ad. It triggers every 5th time a match detail screen is opened.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for interacting with our simulated ad!')),
                    );
                  },
                  child: const Text(
                    'Simulate Action',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Create and return a BannerAd configured with callbacks
  BannerAd? createBannerAd({
    required void Function(Ad ad) onAdLoaded,
    required void Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) {
    if (kIsWeb) return null;
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  // Load Rewarded Ad in background
  void _loadRewardedAd() {
    if (kIsWeb) return;
    if (_isRewardedAdLoading || _rewardedAd != null) return;

    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          _setupRewardedCallbacks(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  void _setupRewardedCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );
  }

  // Track clicks and trigger rewarded ad after 3-4 clicks
  void recordClickAndMaybeShowRewardedAd(BuildContext context, {required VoidCallback onUserEarnedReward}) {
    _rewardedClicksCount++;
    debugPrint('Rewarded Click count: $_rewardedClicksCount / $_rewardedClicksTarget');
    if (_rewardedClicksCount >= _rewardedClicksTarget) {
      // Reset clicks count and randomize next target between 3 and 4
      _rewardedClicksCount = 0;
      _rewardedClicksTarget = 3 + math.Random().nextInt(2); // 3 or 4

      if (kIsWeb) {
        _showWebRewardedAdDialog(context, onUserEarnedReward);
      } else {
        _showRewardedAd(onUserEarnedReward);
      }
    } else {
      // Direct callback if limit not reached
      onUserEarnedReward();
    }
  }

  void _showRewardedAd(VoidCallback onUserEarnedReward) {
    if (kIsWeb) return;
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward();
      });
    } else {
      debugPrint('Rewarded ad not loaded yet, preloading...');
      _loadRewardedAd();
      // Fallback so user action is not blocked if ad load fails or is slow
      onUserEarnedReward();
    }
  }

  void _showWebRewardedAdDialog(BuildContext context, VoidCallback onUserEarnedReward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _WebRewardedAdDialog(onRewardEarned: onUserEarnedReward);
      },
    );
  }
}

// ── Web Rewarded Ad Simulation Widget ──────────────────────────────────────────
class _WebRewardedAdDialog extends StatefulWidget {
  final VoidCallback onRewardEarned;
  const _WebRewardedAdDialog({required this.onRewardEarned});

  @override
  State<_WebRewardedAdDialog> createState() => _WebRewardedAdDialogState();
}

class _WebRewardedAdDialogState extends State<_WebRewardedAdDialog> {
  int _secondsRemaining = 5;
  Timer? _timer;
  bool _rewardEarned = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 1) {
            _secondsRemaining--;
          } else {
            _secondsRemaining = 0;
            _rewardEarned = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 340,
        height: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xEE0A0E21) : const Color(0xEEFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_outline, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'REWARDED AD (TEST)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_rewardEarned)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else
                  Text(
                    '${_secondsRemaining}s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),

            // Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_rewardEarned) ...[
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (5 - _secondsRemaining) / 5.0,
                          strokeWidth: 5,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                        Icon(
                          Icons.play_arrow,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Watching Sponsor Video...',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait a few seconds to earn your reward.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Icon(
                    Icons.stars,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reward Earned!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have successfully unlocked the premium action!',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),

            // Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _rewardEarned ? theme.colorScheme.primary : Colors.grey.withOpacity(0.2),
                foregroundColor: _rewardEarned ? Colors.black : Colors.grey,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _rewardEarned
                  ? () {
                      Navigator.of(context).pop();
                      widget.onRewardEarned();
                    }
                  : null,
              child: Text(
                _rewardEarned ? 'Claim Reward' : 'Watch to Unlock',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

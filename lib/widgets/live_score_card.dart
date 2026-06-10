import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/match.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class LiveScoreCard extends StatefulWidget {
  final Match match;

  const LiveScoreCard({super.key, required this.match});

  @override
  State<LiveScoreCard> createState() => _LiveScoreCardState();
}

class _LiveScoreCardState extends State<LiveScoreCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.go('/match/${widget.match.id}');
        },
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(
            context: context,
            radius: 20,
            fillOpacity: isDark ? 0.06 : 0.04,
            borderOpacity: 0.12,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header: Venue & Live Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.match.venue.split(',').first,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.liveColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _pulseController,
                          child: Container(
                            height: 8,
                            width: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.liveColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "LIVE ${widget.match.currentMinute}'",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.liveColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Teams and Score Line
              Row(
                children: [
                  // Home Team
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            AppConstants.getFlagUrl(widget.match.homeTeam.flagCode),
                            width: 48,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.flag, size: 32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.match.homeTeam.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Score
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: AppConstants.mediumAnimation,
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Text(
                            '${widget.match.homeScore}',
                            key: ValueKey('home-${widget.match.homeScore}'),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          ' - ',
                          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey),
                        ),
                        AnimatedSwitcher(
                          duration: AppConstants.mediumAnimation,
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Text(
                            '${widget.match.awayScore}',
                            key: ValueKey('away-${widget.match.awayScore}'),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Away Team
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            AppConstants.getFlagUrl(widget.match.awayTeam.flagCode),
                            width: 48,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.flag, size: 32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.match.awayTeam.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Footer Event summary
              Text(
                widget.match.events.isNotEmpty
                    ? "${widget.match.events.last.minute}' ${widget.match.events.last.playerName}: ${widget.match.events.last.detail}"
                    : "No major match events yet",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/constants.dart';

class MatchStatBar extends StatelessWidget {
  final String label;
  final int homeVal;
  final int awayVal;
  final bool isPercentage;

  const MatchStatBar({
    super.key,
    required this.label,
    required this.homeVal,
    required this.awayVal,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = homeVal + awayVal;
    
    // Proportions
    final double homePercent = total > 0 ? homeVal / total : 0.5;
    final double awayPercent = total > 0 ? awayVal / total : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // Stat Numbers and Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPercentage ? '$homeVal%' : '$homeVal',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isPercentage ? '$awayVal%' : '$awayVal',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comparison Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              width: double.infinity,
              child: Row(
                children: [
                  // Home Side
                  Expanded(
                    flex: (homePercent * 100).round(),
                    child: AnimatedContainer(
                      duration: AppConstants.mediumAnimation,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2), // Divider gap
                  // Away Side
                  Expanded(
                    flex: (awayPercent * 100).round(),
                    child: AnimatedContainer(
                      duration: AppConstants.mediumAnimation,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

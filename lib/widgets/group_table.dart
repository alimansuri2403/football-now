import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/team.dart';
import '../core/constants.dart';

class GroupTable extends StatelessWidget {
  final String groupName;
  final List<GroupStanding> standings;

  const GroupTable({
    super.key,
    required this.groupName,
    required this.standings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group $groupName Standings',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3.0), // Team Name
              1: FixedColumnWidth(28), // Played
              2: FixedColumnWidth(28), // W
              3: FixedColumnWidth(28), // D
              4: FixedColumnWidth(28), // L
              5: FixedColumnWidth(34), // GD
              6: FixedColumnWidth(34), // Pts
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
                children: [
                  _headerCell(theme, 'Team', alignLeft: true),
                  _headerCell(theme, 'P'),
                  _headerCell(theme, 'W'),
                  _headerCell(theme, 'D'),
                  _headerCell(theme, 'L'),
                  _headerCell(theme, 'GD'),
                  _headerCell(theme, 'PTS'),
                ],
              ),
              // Team Rows
              ...List.generate(standings.length, (index) {
                final standing = standings[index];
                final isQualifying = index < 2; // top 2 qualify

                return TableRow(
                  decoration: BoxDecoration(
                    color: isQualifying 
                        ? (isDark ? Colors.green.withOpacity(0.03) : Colors.green.withOpacity(0.02))
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  children: [
                    // Team cell
                    TableCell(
                      child: InkWell(
                        onTap: () {
                          context.go('/team/${standing.team.id}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.network(
                                  AppConstants.getFlagUrl(standing.team.flagCode),
                                  width: 24,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.flag, size: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  standing.team.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isQualifying ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _valueCell(theme, '${standing.played}'),
                    _valueCell(theme, '${standing.won}'),
                    _valueCell(theme, '${standing.drawn}'),
                    _valueCell(theme, '${standing.lost}'),
                    _valueCell(theme, '${standing.goalDifference}',
                        color: standing.goalDifference > 0
                            ? Colors.green
                            : standing.goalDifference < 0
                                ? Colors.red
                                : Colors.grey),
                    TableCell(
                      child: Center(
                        child: Text(
                          '${standing.points}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isQualifying ? theme.colorScheme.primary : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _headerCell(ThemeData theme, String text, {bool alignLeft = false}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        ),
      ),
    );
  }

  Widget _valueCell(ThemeData theme, String text, {Color? color}) {
    return TableCell(
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
          ),
        ),
      ),
    );
  }
}

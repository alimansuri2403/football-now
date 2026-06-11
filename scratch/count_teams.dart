import '../lib/data/wc2026_data.dart';

void main() {
  print("Total teams in WC2026Data: ${WC2026Data.teams.length}");
  final Map<String, int> groupCounts = {};
  for (final t in WC2026Data.teams) {
    groupCounts[t.group] = (groupCounts[t.group] ?? 0) + 1;
  }
  print("Group distributions:");
  groupCounts.forEach((group, count) {
    print("Group $group: $count teams");
  });
}

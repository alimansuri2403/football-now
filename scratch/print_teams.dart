import 'package:fifa2026_app/data/wc2026_data.dart';

void main() {
  print('Total teams in WC2026Data.teams: ${WC2026Data.teams.length}');
  for (var i = 0; i < WC2026Data.teams.length; i++) {
    final t = WC2026Data.teams[i];
    print('[$i] ${t.name} (Code: ${t.code}, Group: ${t.group})');
  }
}

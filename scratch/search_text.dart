import 'dart:io';

void main() {
  final dir = Directory('C:\\Users\\alima\\Music\\fifa2026_app\\lib');
  if (!dir.existsSync()) {
    print('Directory does not exist');
    return;
  }

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('tournament_provider') || line.contains('TournamentState') || line.contains('TournamentNotifier') || line.contains('tournamentProvider')) {
            print('${entity.path}:${i + 1}: $line');
          }
        }
      } catch (_) {}
    }
  });
}

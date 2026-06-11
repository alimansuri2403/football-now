import 'dart:io';

void main() {
  final dir = Directory('C:\\Users\\alima\\Music');
  final terms = ["South Africa", "Czechia", "South Korea", "Bosnia"];
  bool found = false;

  if (!dir.existsSync()) {
    print('Directory does not exist');
    return;
  }

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File &&
        (entity.path.endsWith('.dart') ||
         entity.path.endsWith('.yaml') ||
         entity.path.endsWith('.json'))) {
      if (entity.path.contains('.dart_tool') ||
          entity.path.contains('build/') ||
          entity.path.contains('.git')) {
        return;
      }
      try {
        final content = entity.readAsStringSync();
        for (final term in terms) {
          if (content.contains(term)) {
            print("Found '$term' in ${entity.path}");
            found = true;
          }
        }
      } catch (_) {}
    }
  });

  if (!found) {
    print("None of the search terms found in files.");
  }
}

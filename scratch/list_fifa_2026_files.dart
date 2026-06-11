import 'dart:io';

void main() {
  final dir = Directory('C:\\Users\\alima\\Music\\fifa_2026');
  if (!dir.existsSync()) {
    print('Directory does not exist');
    return;
  }

  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      print(entity.path);
    }
  });
}

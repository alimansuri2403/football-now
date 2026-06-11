import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/teams?limit=100');
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final Map<String, String> codeToId = {};
      final Map<String, String> codeToName = {};
      
      if (data.containsKey('sports')) {
        final sports = data['sports'] as List<dynamic>;
        for (final sport in sports) {
          final leagues = sport['leagues'] as List<dynamic>? ?? [];
          for (final league in leagues) {
            final teams = league['teams'] as List<dynamic>? ?? [];
            for (final teamContainer in teams) {
              final team = teamContainer['team'] as Map<String, dynamic>;
              final code = team['abbreviation']?.toUpperCase();
              final id = team['id']?.toString();
              final name = team['displayName'];
              if (code != null && id != null) {
                codeToId[code] = id;
                codeToName[code] = name;
              }
            }
          }
        }
      }
      
      print('--- Map codeToId ---');
      codeToId.forEach((code, id) {
        print("  '$code': '$id', // ${codeToName[code]}");
      });
      print('Total mapped teams: ${codeToId.length}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  try {
    final summaryUri = Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/summary?event=760415');
    final request = await client.getUrl(summaryUri);
    request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      if (data.containsKey('headToHeadGames')) {
        final h2h = data['headToHeadGames'] as List<dynamic>;
        if (h2h.isNotEmpty) {
          final first = h2h[0] as Map<String, dynamic>;
          if (first.containsKey('events')) {
            final events = first['events'] as List<dynamic>;
            for (var i = 0; i < events.length; i++) {
              final ev = events[i] as Map<String, dynamic>;
              print('H2H Match $i:');
              print('  Date: ${ev['gameDate']}');
              print('  Competition: ${ev['competitionName']}');
              print('  Score: ${ev['score']}');
              print('  Home Score: ${ev['homeTeamScore']} - Away Score: ${ev['awayTeamScore']}');
              print('  Game Result: ${ev['gameResult']}');
              print('  Opponent Name: ${ev['opponent']?['displayName']}');
            }
          }
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

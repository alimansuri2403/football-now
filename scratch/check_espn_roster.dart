import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  try {
    final rosterUri = Uri.parse('https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/teams/624/roster');
    final request = await client.getUrl(rosterUri);
    request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final athletes = data['athletes'] as List<dynamic>;
      if (athletes.isNotEmpty) {
        final firstAthlete = athletes[0] as Map<String, dynamic>;
        print('Athlete display name: ${firstAthlete['displayName']}');
        print('Athlete jersey: ${firstAthlete['jersey']}');
        print('Athlete age: ${firstAthlete['age']}');
        print('Athlete position map: ${firstAthlete['position']}');
        print('Athlete links: ${firstAthlete['links']}');
        
        // Check if there is an image URL in the athlete data. Usually it's at:
        // https://a.espncdn.com/i/headshots/soccer/players/full/{athleteId}.png
        final athleteId = firstAthlete['id'];
        print('Athlete Headshot URL: https://a.espncdn.com/i/headshots/soccer/players/full/$athleteId.png');
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}

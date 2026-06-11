import requests
import json

# Test fetching teams from ESPN API
url_teams = "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/teams"
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
}

try:
    response = requests.get(url_teams, headers=headers, timeout=10)
    print(f"Teams status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print("Teams root keys:", list(data.keys()))
        if 'sports' in data:
            sports = data['sports']
            print("Sports count:", len(sports))
            for sport in sports:
                print("  Sport:", sport.get('name'))
                leagues = sport.get('leagues', [])
                print("  Leagues count:", len(leagues))
                for league in leagues:
                    print("    League:", league.get('name'))
                    teams = league.get('teams', [])
                    print("    Teams count:", len(teams))
                    if teams:
                        first_team = teams[0]['team']
                        print("    First team keys:", list(first_team.keys()))
                        print("    First team ID:", first_team.get('id'))
                        print("    First team Name:", first_team.get('displayName'))
                        print("    First team Links:", first_team.get('links'))
    else:
        print("Failed to fetch teams:", response.text[:200])
except Exception as e:
    print(f"Error fetching teams: {e}")

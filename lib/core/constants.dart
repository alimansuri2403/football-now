class AppConstants {
  static const String appName = 'FIFA 2026 Scoreboard';
  
  // High quality PNG flags from FlagCDN
  static String getFlagUrl(String countryCode) {
    // lowercase 2-letter country code
    final code = countryCode.toLowerCase();
    return 'https://flagcdn.com/w160/$code.png';
  }

  // Fallback placeholder images
  static const String fallbackTeamLogo = 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=100&auto=format&fit=crop';
  static const String fallbackPlayerPhoto = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop';
  static const String worldCupHeroBanner = 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=1200&auto=format&fit=crop&q=80';

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  static const Duration liveUpdateInterval = Duration(seconds: 15);
}

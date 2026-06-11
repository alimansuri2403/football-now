import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/match.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _liveChannel = AndroidNotificationChannel(
    'live_matches',
    'Live Matches',
    description: 'Alerts when a match goes live',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(initSettings);

      // Create the Android notification channel
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_liveChannel);

      _initialized = true;
      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> showMatchLiveNotification(Match match) async {
    if (kIsWeb || !_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'live_matches',
        'Live Matches',
        channelDescription: 'Alerts when a match goes live',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        ticker: 'Match is Live!',
        styleInformation: BigTextStyleInformation(''),
      );
      const details = NotificationDetails(android: androidDetails);

      final title = '⚽ LIVE: ${match.homeTeam.name} vs ${match.awayTeam.name}';
      final body = match.group != null
          ? 'Group ${match.group} match has kicked off! • ${match.venue}'
          : '${match.stage ?? "Knockout"} match has kicked off! • ${match.venue}';

      await _plugin.show(
        match.id.hashCode,
        title,
        body,
        details,
      );
      debugPrint('Notification sent for match: ${match.id}');
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }
  }
}

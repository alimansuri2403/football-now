import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await AdService().initialize();
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

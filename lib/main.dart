import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService().initialize();
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

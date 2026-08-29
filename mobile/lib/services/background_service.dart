// PLACEHOLDER flutter_background_service entry. Do not start in the demo.
import 'package:flutter_background_service/flutter_background_service.dart';

Future<void> configureBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundStart,
      isForegroundMode: false,
      autoStart: false,
      notificationChannelId: 'synapsix_placeholder',
      initialNotificationTitle: 'Protocol Synapsix',
      initialNotificationContent: 'PLACEHOLDER background sensing',
      foregroundServiceNotificationId: 26168,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onBackgroundStart,
      autoStart: false,
    ),
  );
}

@pragma('vm:entry-point')
void onBackgroundStart(ServiceInstance service) {
  // PLACEHOLDER no-op.
}

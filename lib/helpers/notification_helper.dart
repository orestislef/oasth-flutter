import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._();
  factory NotificationHelper() => _instance;
  NotificationHelper._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<void> scheduleArrivalReminder({
    required int id,
    required String lineId,
    required String vehCode,
    required int minutesUntilArrival,
    required String stopName,
  }) async {
    final delaySeconds = (minutesUntilArrival - 1) * 60;
    if (delaySeconds <= 0) return;

    const androidDetails = AndroidNotificationDetails(
      'bus_arrival_reminders',
      'Bus Arrival Reminders',
      channelDescription: 'Reminders for upcoming bus arrivals',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    Future.delayed(Duration(seconds: delaySeconds), () async {
      try {
        await _plugin.show(
          id: id,
          title: 'Bus Arriving Soon!',
          body: 'Line $lineId (Bus $vehCode) arriving at $stopName in ~1 minute',
          notificationDetails: details,
        );
      } catch (e) {
        debugPrint('Notification error: $e');
      }
    });
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }
}

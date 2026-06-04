// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ========== INTERVIEW NOTIFICATIONS ==========
  
  // Jadwalkan 3 notifikasi sekaligus untuk satu jadwal interview:
  // 1. H-1 hari  → notif penyemangat
  // 2. H-1 jam   → notif siap-siap
  // 3. Tepat waktu → notif "Saatnya interview!"
  //
  // ID yang dipakai:
  //   H-1 hari  : id * 10 + 1
  //   H-1 jam   : id * 10 + 2
  //   Tepat jam : id * 10 + 3
  Future<void> scheduleInterviewNotification({
    required int id,
    required String jobTitle,
    required String companyName,
    required DateTime interviewDateTime,
  }) async {
    final now = DateTime.now();

    const androidHigh = AndroidNotificationDetails(
      'interview_channel',
      'Interview Reminders',
      channelDescription: 'Notifikasi pengingat jadwal interview',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const highDetails = NotificationDetails(android: androidHigh, iOS: iosDetails);

    const androidDefault = AndroidNotificationDetails(
      'interview_cheer_channel',
      'Interview Cheers',
      channelDescription: 'Notifikasi semangat sebelum interview',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const cheerDetails = NotificationDetails(android: androidDefault, iOS: iosDetails);

    // 1. H-1 hari: notif penyemangat 
    final oneDayBefore = interviewDateTime.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        id * 10 + 1,
        '💪 Semangat! Interview besok!',
        'Kamu bisa! Siapkan dirimu untuk $jobTitle di $companyName besok.',
        tz.TZDateTime.from(oneDayBefore, tz.local),
        cheerDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 2. H-1 jam: notif siap-siap
    final oneHourBefore = interviewDateTime.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        id * 10 + 2,
        '⏰ 1 jam lagi — Siap-siap yuk!',
        'Interview di $companyName. Cek perlengkapanmu, tenangkan pikiran, dan tunjukkan yang terbaik!',
        tz.TZDateTime.from(oneHourBefore, tz.local),
        highDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 3. Tepat waktu interview 
    if (interviewDateTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id * 10 + 3,
        '🎯 Waktunya interview!',
        'Saatnya tunjukkan yang terbaik di $companyName.',
        tz.TZDateTime.from(interviewDateTime, tz.local),
        highDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Cancel semua notifikasi milik satu interview (3 ID sekaligus)
  Future<void> cancelNotification(int id) async {
    await Future.wait([
      _plugin.cancel(id * 10 + 1),
      _plugin.cancel(id * 10 + 2),
      _plugin.cancel(id * 10 + 3),
    ]);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ========== JOB APPLICATION NOTIFICATIONS ==========
  
  // Notifikasi instan untuk lamaran pekerjaan berhasil
  Future<void> showJobAppliedNotification({
    required String jobTitle,
    required String companyName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'job_application_channel',
      'Lamaran Pekerjaan',
      channelDescription: 'Notifikasi untuk lamaran pekerjaan',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1A3C5E),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ID unik berdasarkan timestamp
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    
    await _plugin.show(
      notificationId,
      'Lamaran Terkirim! 🎉',
      'Lamaran untuk "$jobTitle" di $companyName telah berhasil dikirim',
      details,
    );
  }

  // Notifikasi umum instan
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      channelDescription: 'Notifikasi umum aplikasi',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
  }
}
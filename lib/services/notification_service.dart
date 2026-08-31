import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/device.dart';

class MaintenanceNotificationSettings {
  const MaintenanceNotificationSettings({
    required this.notificationsEnabled,
    required this.reminderDaysBefore,
    required this.reminderHour,
    required this.reminderMinute,
    required this.overdueNotificationEnabled,
  });

  final bool notificationsEnabled;
  final int reminderDaysBefore;
  final int reminderHour;
  final int reminderMinute;
  final bool overdueNotificationEnabled;
}

class NotificationService {
  static const int _testNotificationId = 0;
  static const String _enabledPreferenceKey = 'notificationEnabled';
  static const String _legacyEnabledPreferenceKey =
      'maintenance_notifications_enabled';
  static const String _reminderDaysBeforePreferenceKey = 'reminderDaysBefore';
  static const String _reminderHourPreferenceKey = 'reminderHour';
  static const String _reminderMinutePreferenceKey = 'reminderMinute';
  static const String _overdueEnabledPreferenceKey =
      'overdueNotificationEnabled';
  static const String _scheduledIdsPreferenceKey =
      'maintenance_notification_scheduled_ids';
  static const String _handledTokensPreferenceKey =
      'maintenance_notification_handled_tokens';

  static const List<int> allowedReminderDaysBefore = [0, 1, 2, 3, 5, 7, 14, 30];

  static const String _channelId = 'maintenance_reminders';
  static const String _channelName = 'Bakım Hatırlatmaları';
  static const String _channelDescription =
      'Yaklaşan ve geciken cihaz bakımları için hatırlatmalar';

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      icon: 'ic_notification',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: _channelId,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: _channelId,
    ),
  );

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool _platformReady = false;
  static bool _notificationsEnabled = true;
  static int _reminderDaysBefore = 1;
  static int _reminderHour = 9;
  static int _reminderMinute = 0;
  static bool _overdueNotificationEnabled = true;

  static bool get notificationsEnabled => _notificationsEnabled;

  static int get reminderDaysBefore => _reminderDaysBefore;

  static int get reminderHour => _reminderHour;

  static int get reminderMinute => _reminderMinute;

  static bool get overdueNotificationEnabled => _overdueNotificationEnabled;

  static MaintenanceNotificationSettings get currentSettings {
    return MaintenanceNotificationSettings(
      notificationsEnabled: _notificationsEnabled,
      reminderDaysBefore: _reminderDaysBefore,
      reminderHour: _reminderHour,
      reminderMinute: _reminderMinute,
      overdueNotificationEnabled: _overdueNotificationEnabled,
    );
  }

  static bool get _supportsNativeNotifications {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  static Future<void> initialize({bool requestPermission = true}) async {
    if (_isInitialized) return;

    timezone_data.initializeTimeZones();
    final preferences = await SharedPreferences.getInstance();
    await _loadPreferences(preferences);

    if (!_supportsNativeNotifications) {
      _isInitialized = true;
      return;
    }

    try {
      final settings = switch (defaultTargetPlatform) {
        TargetPlatform.android => const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        TargetPlatform.iOS => const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        TargetPlatform.macOS => const InitializationSettings(
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        _ => const InitializationSettings(),
      };

      _platformReady = await _plugin.initialize(settings: settings) ?? false;
      _isInitialized = true;

      if (_notificationsEnabled && requestPermission) {
        final permissionGranted = await _requestPermission();
        if (!permissionGranted) {
          _notificationsEnabled = false;
          await _saveNotificationsEnabled(preferences, false);
          await cancelMaintenanceNotifications();
        }
      }
    } catch (error, stackTrace) {
      _isInitialized = true;
      _platformReady = false;
      debugPrint('Bildirim servisi başlatılamadı: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<bool> setNotificationsEnabled({
    required bool enabled,
    required List<Device> devices,
  }) async {
    await initialize(requestPermission: false);
    final preferences = await SharedPreferences.getInstance();

    if (!enabled) {
      _notificationsEnabled = false;
      await _saveNotificationsEnabled(preferences, false);
      await cancelMaintenanceNotifications();
      return false;
    }

    final permissionGranted = await _requestPermission();
    if (!permissionGranted) {
      _notificationsEnabled = false;
      await _saveNotificationsEnabled(preferences, false);
      await cancelMaintenanceNotifications();
      return false;
    }

    _notificationsEnabled = true;
    await _saveNotificationsEnabled(preferences, true);
    await syncMaintenanceNotifications(devices);
    return true;
  }

  static Future<void> setReminderDaysBefore({
    required int daysBefore,
    required List<Device> devices,
  }) async {
    await initialize(requestPermission: false);
    final preferences = await SharedPreferences.getInstance();
    _reminderDaysBefore = _normalizedReminderDaysBefore(daysBefore);
    await preferences.setInt(
      _reminderDaysBeforePreferenceKey,
      _reminderDaysBefore,
    );
    await syncMaintenanceNotifications(devices);
  }

  static Future<void> setReminderTime({
    required int hour,
    required int minute,
    required List<Device> devices,
  }) async {
    await initialize(requestPermission: false);
    final preferences = await SharedPreferences.getInstance();
    _reminderHour = _normalizedHour(hour);
    _reminderMinute = _normalizedMinute(minute);
    await preferences.setInt(_reminderHourPreferenceKey, _reminderHour);
    await preferences.setInt(_reminderMinutePreferenceKey, _reminderMinute);
    await syncMaintenanceNotifications(devices);
  }

  static Future<void> setOverdueNotificationsEnabled({
    required bool enabled,
    required List<Device> devices,
  }) async {
    await initialize(requestPermission: false);
    final preferences = await SharedPreferences.getInstance();
    _overdueNotificationEnabled = enabled;
    await preferences.setBool(_overdueEnabledPreferenceKey, enabled);
    await syncMaintenanceNotifications(devices);
  }

  static Future<void> syncMaintenanceNotifications(List<Device> devices) async {
    await initialize(requestPermission: false);
    final preferences = await SharedPreferences.getInstance();

    try {
      await _cancelTrackedScheduledNotifications(preferences);
      if (!_notificationsEnabled || !_platformReady) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final handledTokens =
          preferences.getStringList(_handledTokensPreferenceKey)?.toSet() ??
          <String>{};
      final validTokens = <String>{};
      final scheduledIds = <int>[];

      for (final device in devices) {
        final maintenanceDate = DateTime(
          device.nextMaintenanceDate.year,
          device.nextMaintenanceDate.month,
          device.nextMaintenanceDate.day,
        );
        final dateKey = _dateKey(maintenanceDate);
        final upcomingToken = 'upcoming:${device.id}:$dateKey';
        final overdueToken = 'overdue:${device.id}:$dateKey';
        validTokens.addAll([upcomingToken, overdueToken]);

        if (maintenanceDate.isBefore(today)) {
          if (!_overdueNotificationEnabled) continue;

          if (!handledTokens.contains(overdueToken)) {
            await _showOverdueNotification(device, maintenanceDate);
            handledTokens.add(overdueToken);
          }
          continue;
        }

        final reminderDate = DateTime(
          maintenanceDate.year,
          maintenanceDate.month,
          maintenanceDate.day - _reminderDaysBefore,
          _reminderHour,
          _reminderMinute,
        );

        if (reminderDate.isAfter(now)) {
          final notificationId = _notificationId(upcomingToken);
          await _plugin.zonedSchedule(
            id: notificationId,
            title: 'Bakım Hatırlatması: ${device.name}',
            body:
                '${device.name} cihazının bakımı ${_formatDate(maintenanceDate)} tarihinde planlandı.',
            scheduledDate: timezone.TZDateTime.from(
              reminderDate.toUtc(),
              timezone.UTC,
            ),
            notificationDetails: _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: device.id,
          );
          scheduledIds.add(notificationId);
          handledTokens.add(upcomingToken);
        } else if (!handledTokens.contains(upcomingToken)) {
          await _showUpcomingNotification(device, maintenanceDate);
          handledTokens.add(upcomingToken);
        }
      }

      handledTokens.retainWhere(validTokens.contains);
      await preferences.setStringList(
        _scheduledIdsPreferenceKey,
        scheduledIds.map((id) => id.toString()).toList(),
      );
      await preferences.setStringList(
        _handledTokensPreferenceKey,
        handledTokens.toList(),
      );
    } catch (error, stackTrace) {
      debugPrint('Bakım bildirimleri güncellenemedi: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> cancelMaintenanceNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    await _cancelTrackedScheduledNotifications(preferences);
  }

  static Future<bool> scheduleTestNotification() async {
    await initialize(requestPermission: false);
    if (!_notificationsEnabled || !_platformReady) return false;

    try {
      await _plugin.cancel(id: _testNotificationId);
      final deliveryTime = DateTime.now().add(const Duration(seconds: 5));

      await _plugin.zonedSchedule(
        id: _testNotificationId,
        title: 'BTMA Test Notification',
        body: 'The local notification system is working correctly.',
        scheduledDate: timezone.TZDateTime.from(
          deliveryTime.toUtc(),
          timezone.UTC,
        ),
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'debug_test_notification',
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Test bildirimi planlanamadı: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<void> _loadPreferences(SharedPreferences preferences) async {
    _notificationsEnabled =
        preferences.getBool(_enabledPreferenceKey) ??
        preferences.getBool(_legacyEnabledPreferenceKey) ??
        true;
    _reminderDaysBefore = _normalizedReminderDaysBefore(
      preferences.getInt(_reminderDaysBeforePreferenceKey),
    );
    _reminderHour = _normalizedHour(
      preferences.getInt(_reminderHourPreferenceKey),
    );
    _reminderMinute = _normalizedMinute(
      preferences.getInt(_reminderMinutePreferenceKey),
    );
    _overdueNotificationEnabled =
        preferences.getBool(_overdueEnabledPreferenceKey) ?? true;

    if (!preferences.containsKey(_enabledPreferenceKey)) {
      await preferences.setBool(_enabledPreferenceKey, _notificationsEnabled);
    }
    if (!preferences.containsKey(_legacyEnabledPreferenceKey)) {
      await preferences.setBool(
        _legacyEnabledPreferenceKey,
        _notificationsEnabled,
      );
    }
    if (!preferences.containsKey(_reminderDaysBeforePreferenceKey)) {
      await preferences.setInt(
        _reminderDaysBeforePreferenceKey,
        _reminderDaysBefore,
      );
    }
    if (!preferences.containsKey(_reminderHourPreferenceKey)) {
      await preferences.setInt(_reminderHourPreferenceKey, _reminderHour);
    }
    if (!preferences.containsKey(_reminderMinutePreferenceKey)) {
      await preferences.setInt(_reminderMinutePreferenceKey, _reminderMinute);
    }
    if (!preferences.containsKey(_overdueEnabledPreferenceKey)) {
      await preferences.setBool(
        _overdueEnabledPreferenceKey,
        _overdueNotificationEnabled,
      );
    }
  }

  static Future<void> _saveNotificationsEnabled(
    SharedPreferences preferences,
    bool enabled,
  ) async {
    await preferences.setBool(_enabledPreferenceKey, enabled);
    await preferences.setBool(_legacyEnabledPreferenceKey, enabled);
  }

  static int _normalizedReminderDaysBefore(int? value) {
    if (value != null && allowedReminderDaysBefore.contains(value)) {
      return value;
    }
    return 1;
  }

  static int _normalizedHour(int? value) {
    if (value != null && value >= 0 && value <= 23) return value;
    return 9;
  }

  static int _normalizedMinute(int? value) {
    if (value != null && value >= 0 && value <= 59) return value;
    return 0;
  }

  static Future<void> _cancelTrackedScheduledNotifications(
    SharedPreferences preferences,
  ) async {
    final scheduledIds =
        preferences.getStringList(_scheduledIdsPreferenceKey) ?? const [];

    if (_platformReady) {
      for (final value in scheduledIds) {
        final id = int.tryParse(value);
        if (id != null) {
          await _plugin.cancel(id: id);
        }
      }
    }

    await preferences.remove(_scheduledIdsPreferenceKey);
  }

  static Future<bool> _requestPermission() async {
    if (!_platformReady) return !_supportsNativeNotifications;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            true,
      TargetPlatform.iOS =>
        await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            true,
      TargetPlatform.macOS =>
        await _plugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            true,
      _ => true,
    };
  }

  static Future<void> _showUpcomingNotification(
    Device device,
    DateTime maintenanceDate,
  ) async {
    final token = 'upcoming:${device.id}:${_dateKey(maintenanceDate)}';
    await _plugin.show(
      id: _notificationId(token),
      title: 'Bakım Hatırlatması: ${device.name}',
      body:
          '${device.name} cihazının bakımı ${_formatDate(maintenanceDate)} tarihinde planlandı.',
      notificationDetails: _notificationDetails,
      payload: device.id,
    );
  }

  static Future<void> _showOverdueNotification(
    Device device,
    DateTime maintenanceDate,
  ) async {
    final token = 'overdue:${device.id}:${_dateKey(maintenanceDate)}';
    await _plugin.show(
      id: _notificationId(token),
      title: 'Geciken Bakım: ${device.name}',
      body:
          '${device.name} cihazının ${_formatDate(maintenanceDate)} tarihli bakımı gecikti.',
      notificationDetails: _notificationDetails,
      payload: device.id,
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}$month$day';
  }

  static int _notificationId(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }
}

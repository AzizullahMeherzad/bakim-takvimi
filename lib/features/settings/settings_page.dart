import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/device_service.dart';
import '../../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _notificationsEnabled;
  late int _reminderDaysBefore;
  late int _reminderHour;
  late int _reminderMinute;
  late bool _overdueNotificationEnabled;

  bool _isSaving = false;
  bool _isSchedulingTestNotification = false;

  @override
  void initState() {
    super.initState();
    final settings = NotificationService.currentSettings;
    _notificationsEnabled = settings.notificationsEnabled;
    _reminderDaysBefore = settings.reminderDaysBefore;
    _reminderHour = settings.reminderHour;
    _reminderMinute = settings.reminderMinute;
    _overdueNotificationEnabled = settings.overdueNotificationEnabled;
  }

  String _reminderDaysLabel(int daysBefore) {
    return switch (daysBefore) {
      0 => 'Aynı gün',
      1 => '1 gün önce',
      _ => '$daysBefore gün önce',
    };
  }

  String _formattedTime() {
    final hour = _reminderHour.toString().padLeft(2, '0');
    final minute = _reminderMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showUpdatedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bildirim ayarları güncellendi.')),
    );
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final actualValue = await NotificationService.setNotificationsEnabled(
      enabled: enabled,
      devices: DeviceService.getDevices(),
    );

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = actualValue;
      _isSaving = false;
    });

    if (enabled && !actualValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bildirim izni verilmedi. Ayarlardan izin vererek tekrar deneyebilirsiniz.',
          ),
        ),
      );
      return;
    }

    _showUpdatedMessage();
  }

  Future<void> _setReminderDaysBefore(int? value) async {
    if (value == null || _isSaving || !_notificationsEnabled) return;
    setState(() {
      _isSaving = true;
      _reminderDaysBefore = value;
    });

    await NotificationService.setReminderDaysBefore(
      daysBefore: value,
      devices: DeviceService.getDevices(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    _showUpdatedMessage();
  }

  Future<void> _pickReminderTime() async {
    if (_isSaving || !_notificationsEnabled) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      helpText: 'Bildirim saati',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );

    if (!mounted || selectedTime == null) return;
    setState(() {
      _isSaving = true;
      _reminderHour = selectedTime.hour;
      _reminderMinute = selectedTime.minute;
    });

    await NotificationService.setReminderTime(
      hour: selectedTime.hour,
      minute: selectedTime.minute,
      devices: DeviceService.getDevices(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    _showUpdatedMessage();
  }

  Future<void> _setOverdueNotificationsEnabled(bool enabled) async {
    if (_isSaving || !_notificationsEnabled) return;
    setState(() {
      _isSaving = true;
      _overdueNotificationEnabled = enabled;
    });

    await NotificationService.setOverdueNotificationsEnabled(
      enabled: enabled,
      devices: DeviceService.getDevices(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    _showUpdatedMessage();
  }

  Future<void> _scheduleTestNotification() async {
    if (_isSchedulingTestNotification || !_notificationsEnabled) return;
    setState(() => _isSchedulingTestNotification = true);

    final scheduled = await NotificationService.scheduleTestNotification();

    if (!mounted) return;
    setState(() => _isSchedulingTestNotification = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scheduled
              ? 'Test bildirimi 5 saniye sonrası için planlandı.'
              : 'Test bildirimi planlanamadı. Bildirim iznini kontrol edin.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.settings_outlined,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ayarlar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bakım hatırlatma davranışlarını buradan yönetin.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _NotificationSettingsCard(
                      notificationsEnabled: _notificationsEnabled,
                      reminderDaysBefore: _reminderDaysBefore,
                      selectedTimeLabel: _formattedTime(),
                      overdueNotificationEnabled: _overdueNotificationEnabled,
                      isSaving: _isSaving,
                      onNotificationsChanged: _setNotificationsEnabled,
                      onReminderDaysChanged: _setReminderDaysBefore,
                      onReminderTimeTap: _pickReminderTime,
                      onOverdueChanged: _setOverdueNotificationsEnabled,
                      reminderDaysLabel: _reminderDaysLabel,
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      _DebugNotificationCard(
                        notificationsEnabled: _notificationsEnabled,
                        isScheduling: _isSchedulingTestNotification,
                        onScheduleTest: _scheduleTestNotification,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  const _NotificationSettingsCard({
    required this.notificationsEnabled,
    required this.reminderDaysBefore,
    required this.selectedTimeLabel,
    required this.overdueNotificationEnabled,
    required this.isSaving,
    required this.onNotificationsChanged,
    required this.onReminderDaysChanged,
    required this.onReminderTimeTap,
    required this.onOverdueChanged,
    required this.reminderDaysLabel,
  });

  final bool notificationsEnabled;
  final int reminderDaysBefore;
  final String selectedTimeLabel;
  final bool overdueNotificationEnabled;
  final bool isSaving;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<int?> onReminderDaysChanged;
  final VoidCallback onReminderTimeTap;
  final ValueChanged<bool> onOverdueChanged;
  final String Function(int daysBefore) reminderDaysLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bildirim Ayarları',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Yaklaşan ve geciken bakımlar için yerel bildirimleri yapılandırın.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bildirimler'),
              subtitle: const Text(
                'Kapalıyken tüm planlı bakım bildirimleri iptal edilir.',
              ),
              value: notificationsEnabled,
              onChanged: isSaving ? null : onNotificationsChanged,
            ),
            const Divider(),
            DropdownButtonFormField<int>(
              initialValue: reminderDaysBefore,
              decoration: const InputDecoration(
                labelText: 'Bakımdan kaç gün önce?',
                helperText:
                    'Yaklaşan bakım bildiriminin bakım tarihinden önceki gününü belirler.',
              ),
              items: NotificationService.allowedReminderDaysBefore
                  .map(
                    (daysBefore) => DropdownMenuItem<int>(
                      value: daysBefore,
                      child: Text(reminderDaysLabel(daysBefore)),
                    ),
                  )
                  .toList(),
              onChanged: notificationsEnabled && !isSaving
                  ? onReminderDaysChanged
                  : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: notificationsEnabled && !isSaving,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Bildirim saati'),
              subtitle: const Text(
                'Yaklaşan bakım bildiriminin gönderileceği saat.',
              ),
              trailing: Text(
                selectedTimeLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: notificationsEnabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: notificationsEnabled && !isSaving
                  ? onReminderTimeTap
                  : null,
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Geciken bakım bildirimi'),
              subtitle: const Text(
                'Açıkken tarihi geçmiş bakımlar için tek seferlik uyarı gösterilir.',
              ),
              value: overdueNotificationEnabled,
              onChanged: notificationsEnabled && !isSaving
                  ? onOverdueChanged
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugNotificationCard extends StatelessWidget {
  const _DebugNotificationCard({
    required this.notificationsEnabled,
    required this.isScheduling,
    required this.onScheduleTest,
  });

  final bool notificationsEnabled;
  final bool isScheduling;
  final VoidCallback onScheduleTest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.bug_report_outlined,
            color: colorScheme.onTertiaryContainer,
          ),
        ),
        title: const Text('Test Notification'),
        subtitle: Text(
          notificationsEnabled
              ? '5 saniye sonra test bildirimi gönder'
              : 'Test için önce bildirimleri açın',
        ),
        trailing: isScheduling
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow_rounded),
        enabled: notificationsEnabled && !isScheduling,
        onTap: notificationsEnabled && !isScheduling ? onScheduleTest : null,
      ),
    );
  }
}

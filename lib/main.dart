import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'features/devices/add_device_page.dart';
import 'features/devices/device_detail_page.dart';
import 'features/devices/device_list_page.dart';
import 'features/maintenance/maintenance_calendar_page.dart';
import 'features/maintenance/maintenance_history_page.dart';
import 'features/settings/settings_page.dart';
import 'models/device.dart';
import 'services/device_service.dart';
import 'services/maintenance_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceService.loadDevices();
  await MaintenanceService.loadRecords();
  await NotificationService.initialize();
  await NotificationService.syncMaintenanceNotifications(
    DeviceService.getDevices(),
  );

  runApp(const BakimTakvimiApp());
}

class BakimTakvimiApp extends StatelessWidget {
  const BakimTakvimiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bakım Takvimi',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<void> _openPage(Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => page));

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAddDevicePage() => _openPage(const AddDevicePage());

  Future<void> _openDeviceListPage() => _openPage(const DeviceListPage());

  Future<void> _openMaintenanceCalendarPage() =>
      _openPage(const MaintenanceCalendarPage());

  Future<void> _openMaintenanceHistoryPage() =>
      _openPage(const MaintenanceHistoryPage());

  Future<void> _openSettingsPage() => _openPage(const SettingsPage());

  Future<void> _openDeviceDetailPage(Device device) =>
      _openPage(DeviceDetailPage(device: device));

  Future<void> _handleDrawerDestination(int index) async {
    Navigator.of(context).pop();

    switch (index) {
      case 0:
        return;
      case 1:
        await _openDeviceListPage();
        return;
      case 2:
        await _openMaintenanceCalendarPage();
        return;
      case 3:
        await _openMaintenanceHistoryPage();
        return;
      case 4:
        _showRoadmapMessage('Raporlar');
        return;
      case 5:
        await _openSettingsPage();
        return;
      case 6:
        await _showLogoutInformation();
        return;
    }
  }

  void _showRoadmapMessage(String feature) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature özelliği yol haritasında yer alıyor')),
    );
  }

  Future<void> _showLogoutInformation() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Çıkış yap'),
        content: const Text(
          'Kimlik doğrulama henüz etkin olmadığı için açık bir kullanıcı oturumu bulunmuyor.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _maintenanceTiming(Device device) {
    if (device.isOverdue) {
      final days = DateTime.now().difference(device.nextMaintenanceDate).inDays;
      return days <= 0 ? 'Bugün gecikti' : '$days gün gecikti';
    }

    final days = device.nextMaintenanceDate.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Bugün';
    if (days == 1) return 'Yarın';
    return '$days gün kaldı';
  }

  Color _statusColor(BuildContext context, Device device) {
    if (device.isOverdue) return Theme.of(context).colorScheme.error;
    if (device.isUpcoming) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final devices = List<Device>.of(DeviceService.getDevices())
      ..sort(
        (first, second) =>
            first.nextMaintenanceDate.compareTo(second.nextMaintenanceDate),
      );
    final total = DeviceService.totalDevices;
    final upcoming = DeviceService.upcomingCount;
    final overdue = DeviceService.overdueCount;
    final normal = total - upcoming - overdue;

    return Scaffold(
      appBar: AppBar(title: const Text('Bakım Takip Paneli')),
      drawer: NavigationDrawer(
        selectedIndex: 0,
        onDestinationSelected: _handleDrawerDestination,
        children: [
          const _DrawerHeader(),
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: Text('Ana Sayfa'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other_rounded),
            label: Text('Cihazlar'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: Text('Bakım Takvimi'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: Text('Bakım Geçmişi'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment_rounded),
            label: Text('Raporlar'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: Text('Ayarlar'),
          ),
          const Divider(indent: 28, endIndent: 28),
          const NavigationDrawerDestination(
            icon: Icon(Icons.logout_rounded),
            selectedIcon: Icon(Icons.logout_rounded),
            label: Text('Çıkış Yap'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = constraints.maxWidth >= 600 ? 24.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    32,
                  ),
                  children: [
                    _StatisticsGrid(
                      total: total,
                      upcoming: upcoming,
                      overdue: overdue,
                    ),
                    const SizedBox(height: 20),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _StatusChart(
                              total: total,
                              normal: normal,
                              upcoming: upcoming,
                              overdue: overdue,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _MaintenancePreview(
                              devices: devices,
                              formatDate: _formatDate,
                              timingLabel: _maintenanceTiming,
                              statusColor: _statusColor,
                              onOpenCalendar: _openMaintenanceCalendarPage,
                              onOpenDevice: _openDeviceDetailPage,
                              onAddDevice: _openAddDevicePage,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _StatusChart(
                        total: total,
                        normal: normal,
                        upcoming: upcoming,
                        overdue: overdue,
                      ),
                      const SizedBox(height: 20),
                      _MaintenancePreview(
                        devices: devices,
                        formatDate: _formatDate,
                        timingLabel: _maintenanceTiming,
                        statusColor: _statusColor,
                        onOpenCalendar: _openMaintenanceCalendarPage,
                        onOpenDevice: _openDeviceDetailPage,
                        onAddDevice: _openAddDevicePage,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.handyman_outlined,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bakım Yönetimi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Kurumsal takip',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({
    required this.total,
    required this.upcoming,
    required this.overdue,
  });

  final int total;
  final int upcoming;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: _StatisticCard(
                valueKey: const Key('dashboard-total-value'),
                title: 'Toplam',
                value: total,
                icon: Icons.precision_manufacturing_outlined,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: spacing),
            SizedBox(
              width: cardWidth,
              child: _StatisticCard(
                valueKey: const Key('dashboard-upcoming-value'),
                title: 'Yaklaşan',
                value: upcoming,
                icon: Icons.schedule_outlined,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: spacing),
            SizedBox(
              width: cardWidth,
              child: _StatisticCard(
                valueKey: const Key('dashboard-overdue-value'),
                title: 'Geciken',
                value: overdue,
                icon: Icons.warning_amber_rounded,
                color: colorScheme.error,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.valueKey,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final Key valueKey;
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              '$value',
              key: valueKey,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({
    required this.total,
    required this.normal,
    required this.upcoming,
    required this.overdue,
  });

  final int total;
  final int normal;
  final int upcoming;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalColor = Colors.green.shade700;
    final upcomingColor = Colors.orange.shade700;
    final overdueColor = colorScheme.error;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bakım durumu',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Cihazların güncel bakım dağılımı',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (total == 0)
              const _ChartEmptyState()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  final chart = SizedBox(
                    height: 190,
                    width: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 54,
                            startDegreeOffset: -90,
                            sections: [
                              if (normal > 0)
                                PieChartSectionData(
                                  value: normal.toDouble(),
                                  color: normalColor,
                                  radius: 34,
                                  showTitle: false,
                                ),
                              if (upcoming > 0)
                                PieChartSectionData(
                                  value: upcoming.toDouble(),
                                  color: upcomingColor,
                                  radius: 34,
                                  showTitle: false,
                                ),
                              if (overdue > 0)
                                PieChartSectionData(
                                  value: overdue.toDouble(),
                                  color: overdueColor,
                                  radius: 34,
                                  showTitle: false,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'cihaz',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                  final legend = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ChartLegend(
                        label: 'Normal',
                        value: normal,
                        color: normalColor,
                      ),
                      const SizedBox(height: 12),
                      _ChartLegend(
                        label: 'Yaklaşan',
                        value: upcoming,
                        color: upcomingColor,
                      ),
                      const SizedBox(height: 12),
                      _ChartLegend(
                        label: 'Geciken',
                        value: overdue,
                        color: overdueColor,
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      children: [chart, const SizedBox(height: 16), legend],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      chart,
                      Flexible(child: legend),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 190,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.donut_large_outlined,
              size: 44,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Grafik için cihaz verisi bekleniyor',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 72, child: Text(label)),
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MaintenancePreview extends StatelessWidget {
  const _MaintenancePreview({
    required this.devices,
    required this.formatDate,
    required this.timingLabel,
    required this.statusColor,
    required this.onOpenCalendar,
    required this.onOpenDevice,
    required this.onAddDevice,
  });

  final List<Device> devices;
  final String Function(DateTime date) formatDate;
  final String Function(Device device) timingLabel;
  final Color Function(BuildContext context, Device device) statusColor;
  final VoidCallback onOpenCalendar;
  final ValueChanged<Device> onOpenDevice;
  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewDevices = devices.take(3).toList();

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bakım öncelikleri',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tarihe göre ilk bakım kayıtları',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (devices.isNotEmpty)
                  TextButton(
                    onPressed: onOpenCalendar,
                    child: const Text('Tümünü gör'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (previewDevices.isEmpty)
              _MaintenanceEmptyState(onAddDevice: onAddDevice)
            else
              ...previewDevices.map((device) {
                final color = statusColor(context, device);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onOpenDevice(device),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                device.isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.build_circle_outlined,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${formatDate(device.nextMaintenanceDate)} • ${timingLabel(device)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: color),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceEmptyState extends StatelessWidget {
  const _MaintenanceEmptyState({required this.onAddDevice});

  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 190,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 44,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text('Henüz bakım kaydı yok'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAddDevice,
              icon: const Icon(Icons.add_rounded),
              label: const Text('İlk cihazı ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

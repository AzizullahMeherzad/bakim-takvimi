import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../services/device_service.dart';
import '../devices/add_device_page.dart';
import '../devices/device_detail_page.dart';

class MaintenanceCalendarPage extends StatefulWidget {
  const MaintenanceCalendarPage({super.key});

  @override
  State<MaintenanceCalendarPage> createState() =>
      _MaintenanceCalendarPageState();
}

class _MaintenanceCalendarPageState extends State<MaintenanceCalendarPage> {
  static const _filters = ['Tümü', 'Yaklaşan', 'Geciken', '30 Gün'];

  final _searchController = TextEditingController();
  String _searchText = '';
  String _selectedFilter = 'Tümü';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  String _timingLabel(Device device) {
    final days = _daysUntil(device.nextMaintenanceDate);
    if (days < 0) return '${days.abs()} gün gecikti';
    if (days == 0) return 'Bugün';
    if (days == 1) return 'Yarın';
    return '$days gün kaldı';
  }

  String _statusText(Device device) {
    if (device.isOverdue) return 'Gecikmiş';
    if (device.isUpcoming) return 'Yaklaşıyor';
    return 'Planlı';
  }

  Color _statusColor(BuildContext context, Device device) {
    if (device.isOverdue) return Theme.of(context).colorScheme.error;
    if (device.isUpcoming) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  bool _matchesFilter(Device device) {
    switch (_selectedFilter) {
      case 'Geciken':
        return device.isOverdue;
      case 'Yaklaşan':
        return device.isUpcoming;
      case '30 Gün':
        final days = _daysUntil(device.nextMaintenanceDate);
        return days >= 0 && days <= 30;
      default:
        return true;
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedFilter = 'Tümü';
    });
  }

  Future<void> _openDevice(Device device) async {
    await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (context) => DeviceDetailPage(device: device),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAddDevicePage() async {
    await Navigator.of(context).push<Device>(
      MaterialPageRoute<Device>(builder: (context) => const AddDevicePage()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final devices = List<Device>.of(DeviceService.getDevices())
      ..sort(
        (first, second) =>
            first.nextMaintenanceDate.compareTo(second.nextMaintenanceDate),
      );
    final query = _searchText.trim().toLowerCase();
    final filteredDevices = devices.where((device) {
      final matchesSearch =
          device.name.toLowerCase().contains(query) ||
          device.category.toLowerCase().contains(query) ||
          device.location.toLowerCase().contains(query) ||
          device.serialNumber.toLowerCase().contains(query);
      return matchesSearch && _matchesFilter(device);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bakım takvimi')),
      body: devices.isEmpty
          ? _EmptyMaintenanceList(onAddDevice: _openAddDevicePage)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MaintenanceSummary(devices: devices),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchText = value),
                            decoration: InputDecoration(
                              labelText: 'Bakım kaydı ara',
                              hintText:
                                  'Cihaz, kategori, konum veya seri numarası',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchText.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Aramayı temizle',
                                      onPressed: _resetFilters,
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _filters
                                  .map(
                                    (filter) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(filter),
                                        selected: _selectedFilter == filter,
                                        onSelected: (_) => setState(
                                          () => _selectedFilter = filter,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredDevices.isEmpty
                      ? _NoMaintenanceResults(onReset: _resetFilters)
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                              itemCount: filteredDevices.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final device = filteredDevices[index];
                                return _MaintenanceCard(
                                  device: device,
                                  date: _formatDate(device.nextMaintenanceDate),
                                  timing: _timingLabel(device),
                                  status: _statusText(device),
                                  statusColor: _statusColor(context, device),
                                  onTap: () => _openDevice(device),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _MaintenanceSummary extends StatelessWidget {
  const _MaintenanceSummary({required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final overdue = devices.where((device) => device.isOverdue).length;
    final upcoming = devices.where((device) => device.isUpcoming).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${devices.length} planlı bakım',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$upcoming yaklaşan • $overdue geciken',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.82),
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

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.device,
    required this.date,
    required this.timing,
    required this.status,
    required this.statusColor,
    required this.onTap,
  });

  final Device device;
  final String date;
  final String timing;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateParts = date.split('.');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      dateParts.first,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${dateParts[1]}.${dateParts[2]}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.category} • ${device.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 17,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$timing • ${device.maintenanceIntervalLabel}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: statusColor),
                        ),
                      ],
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
    );
  }
}

class _EmptyMaintenanceList extends StatelessWidget {
  const _EmptyMaintenanceList({required this.onAddDevice});

  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Bakım planı henüz boş',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bir cihaz eklediğinizde sonraki bakım tarihi otomatik olarak burada görünür.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onAddDevice,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Cihaz ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMaintenanceResults extends StatelessWidget {
  const _NoMaintenanceResults({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Eşleşen bakım kaydı bulunamadı'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onReset,
            child: const Text('Filtreleri temizle'),
          ),
        ],
      ),
    );
  }
}

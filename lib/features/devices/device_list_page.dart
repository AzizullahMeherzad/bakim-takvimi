import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../services/device_service.dart';
import 'add_device_page.dart';
import 'device_detail_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  static const _filters = ['Tümü', 'Planlı', 'Yaklaşan', 'Geciken'];

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
      case 'Planlı':
        return !device.isOverdue && !device.isUpcoming;
      case 'Yaklaşan':
        return device.isUpcoming;
      case 'Geciken':
        return device.isOverdue;
      default:
        return true;
    }
  }

  Future<void> _openAddDevicePage() async {
    await Navigator.of(context).push<Device>(
      MaterialPageRoute<Device>(builder: (context) => const AddDevicePage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openDevice(Device device) async {
    await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (context) => DeviceDetailPage(device: device),
      ),
    );
    if (mounted) setState(() {});
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedFilter = 'Tümü';
    });
  }

  @override
  Widget build(BuildContext context) {
    final allDevices = List<Device>.of(DeviceService.getDevices())
      ..sort((first, second) => first.name.compareTo(second.name));
    final query = _searchText.trim().toLowerCase();
    final filteredDevices = allDevices.where((device) {
      final matchesSearch =
          device.name.toLowerCase().contains(query) ||
          device.category.toLowerCase().contains(query) ||
          device.location.toLowerCase().contains(query) ||
          device.serialNumber.toLowerCase().contains(query);
      return matchesSearch && _matchesFilter(device);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cihazlar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDevicePage,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni cihaz'),
      ),
      body: allDevices.isEmpty
          ? _EmptyDeviceList(onAddDevice: _openAddDevicePage)
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
                          _InventorySummary(devices: allDevices),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchText = value),
                            decoration: InputDecoration(
                              labelText: 'Cihaz ara',
                              hintText:
                                  'Ad, kategori, konum veya seri numarası',
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
                      ? _NoDeviceResults(onClear: _resetFilters)
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                              itemCount: filteredDevices.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final device = filteredDevices[index];
                                return _DeviceCard(
                                  device: device,
                                  status: _statusText(device),
                                  statusColor: _statusColor(context, device),
                                  nextMaintenanceDate: _formatDate(
                                    device.nextMaintenanceDate,
                                  ),
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

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final overdue = devices.where((device) => device.isOverdue).length;
    final upcoming = devices.where((device) => device.isUpcoming).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${devices.length} kayıtlı cihaz',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$upcoming yaklaşan • $overdue geciken bakım',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
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

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.status,
    required this.statusColor,
    required this.nextMaintenanceDate,
    required this.onTap,
  });

  final Device device;
  final String status;
  final Color statusColor;
  final String nextMaintenanceDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  device.isOverdue
                      ? Icons.warning_amber_rounded
                      : device.isUpcoming
                      ? Icons.schedule_rounded
                      : Icons.precision_manufacturing_outlined,
                  color: statusColor,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
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
                          Icons.event_outlined,
                          size: 17,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Sonraki bakım: $nextMaintenanceDate • ${device.maintenanceIntervalLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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

class _EmptyDeviceList extends StatelessWidget {
  const _EmptyDeviceList({required this.onAddDevice});

  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Cihaz envanteri boş',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İlk cihazınızı ekleyerek bakım planını oluşturmaya başlayın.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onAddDevice,
                icon: const Icon(Icons.add_rounded),
                label: const Text('İlk cihazı ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDeviceResults extends StatelessWidget {
  const _NoDeviceResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('Eşleşen cihaz bulunamadı'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClear,
            child: const Text('Filtreleri temizle'),
          ),
        ],
      ),
    );
  }
}

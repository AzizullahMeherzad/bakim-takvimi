import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/maintenance_record.dart';
import '../../services/device_service.dart';
import '../../services/maintenance_service.dart';
import '../maintenance/maintenance_completion_page.dart';
import '../maintenance/widgets/maintenance_document_widgets.dart';
import '../maintenance/widgets/maintenance_photo_widgets.dart';
import 'edit_device_page.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({super.key, required this.device});

  final Device device;

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late Device _device;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get _statusText {
    if (_device.isOverdue) return 'Gecikmiş';
    if (_device.isUpcoming) return 'Yaklaşıyor';
    return 'Planlı';
  }

  IconData get _statusIcon {
    if (_device.isOverdue) return Icons.warning_amber_rounded;
    if (_device.isUpcoming) return Icons.schedule_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Color _statusColor(BuildContext context) {
    if (_device.isOverdue) return Theme.of(context).colorScheme.error;
    if (_device.isUpcoming) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  String get _documentName {
    final path = _device.documentPath;
    if (path == null || path.isEmpty) return 'Belge eklenmedi';
    return path.split(RegExp(r'[\\/]')).last;
  }

  void _showPdfRoadmapMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF belge desteği Phase 2 kapsamında eklenecek'),
      ),
    );
  }

  Future<void> _editDevice() async {
    final updatedDevice = await Navigator.of(context).push<Device>(
      MaterialPageRoute<Device>(
        builder: (context) => EditDevicePage(device: _device),
      ),
    );

    if (updatedDevice != null && mounted) {
      setState(() => _device = updatedDevice);
    }
  }

  Future<void> _completeMaintenance() async {
    final result = await Navigator.of(context)
        .push<MaintenanceCompletionResult>(
          MaterialPageRoute<MaintenanceCompletionResult>(
            builder: (context) => MaintenanceCompletionPage(device: _device),
          ),
        );

    if (!mounted || result == null) return;
    if (result.updatedDevice != null) {
      setState(() => _device = result.updatedDevice!);
    } else {
      setState(() {});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.savedAsDraft
              ? 'Yeni bakım notu kaydedildi.'
              : 'Bakım tamamlandı.',
        ),
      ),
    );
  }

  Future<void> _deleteDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Cihaz silinsin mi?'),
        content: Text(
          '${_device.name} cihazı ve bakım planı kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await DeviceService.deleteDevice(_device.id);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cihaz silindi')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(context);
    final maintenanceHistory = MaintenanceService.recordsForDevice(_device.id);
    final activeMaintenance = MaintenanceService.activeRecordForDevice(
      _device.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cihaz detayı'),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            onPressed: _editDevice,
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.precision_manufacturing_outlined,
                            color: colorScheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _device.name,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_device.category} • ${_device.location}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onPrimary.withValues(
                                        alpha: 0.82,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: statusColor.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(_statusIcon, color: statusColor, size: 30),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bakım durumu',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(
                                  _statusText,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Sonraki bakım',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                _formatDate(_device.nextMaintenanceDate),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cihaz bilgileri',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.category_outlined,
                            label: 'Kategori',
                            value: _device.category,
                          ),
                          _DetailRow(
                            icon: Icons.qr_code_2_outlined,
                            label: 'Seri numarası',
                            value: _device.serialNumber,
                          ),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Konum',
                            value: _device.location,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bakım planı',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.history_rounded,
                            label: 'Son bakım',
                            value: _formatDate(_device.lastMaintenanceDate),
                          ),
                          _DetailRow(
                            icon: Icons.event_repeat_outlined,
                            label: 'Bakım periyodu',
                            value: _device.maintenanceIntervalLabel,
                          ),
                          _DetailRow(
                            icon: Icons.tune_rounded,
                            label: 'Sonraki bakım hesabı',
                            value: _device.maintenanceCalculationMethodLabel,
                          ),
                          _DetailRow(
                            icon: Icons.event_available_outlined,
                            label: 'Sonraki bakım',
                            value: _formatDate(_device.nextMaintenanceDate),
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _completeMaintenance,
                              icon: Icon(
                                activeMaintenance == null
                                    ? Icons.playlist_add_check_rounded
                                    : Icons.pending_actions_rounded,
                              ),
                              label: Text(
                                activeMaintenance == null
                                    ? 'Bakımı Başlat'
                                    : 'Bakıma Devam Et',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (activeMaintenance != null) ...[
                    const SizedBox(height: 16),
                    _ActiveMaintenanceCard(
                      record: activeMaintenance,
                      formatDate: _formatDate,
                      formatTime: _formatTime,
                      onContinue: _completeMaintenance,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _MaintenanceHistoryCard(
                    records: maintenanceHistory,
                    formatDate: _formatDate,
                    formatTime: _formatTime,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      title: const Text('Bakım belgesi'),
                      subtitle: Text(_documentName),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showPdfRoadmapMessage,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 600;
                      final editButton = FilledButton.icon(
                        onPressed: _editDevice,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Cihazı düzenle'),
                      );
                      final pdfButton = OutlinedButton.icon(
                        onPressed: _showPdfRoadmapMessage,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('PDF belge ekle'),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 52, child: editButton),
                            const SizedBox(height: 10),
                            SizedBox(height: 52, child: pdfButton),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: SizedBox(height: 52, child: editButton),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(height: 52, child: pdfButton),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _deleteDevice,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Cihazı sil'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceHistoryCard extends StatelessWidget {
  const _MaintenanceHistoryCard({
    required this.records,
    required this.formatDate,
    required this.formatTime,
  });

  final List<MaintenanceRecord> records;
  final String Function(DateTime date) formatDate;
  final String Function(DateTime date) formatTime;

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
                Expanded(
                  child: Text(
                    'Bakım Geçmişi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (records.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${records.length} kayıt',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (records.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 40,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bu cihaz için henüz tamamlanmış bakım kaydı yok.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(records.length, (index) {
                return Column(
                  children: [
                    _MaintenanceHistoryItem(
                      record: records[index],
                      formattedDate: formatDate(records[index].completedDate),
                      formatDate: formatDate,
                      formatTime: formatTime,
                    ),
                    if (index < records.length - 1) const Divider(height: 24),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ActiveMaintenanceCard extends StatelessWidget {
  const _ActiveMaintenanceCard({
    required this.record,
    required this.formatDate,
    required this.formatTime,
    required this.onContinue,
  });

  final MaintenanceRecord record;
  final String Function(DateTime date) formatDate;
  final String Function(DateTime date) formatTime;
  final VoidCallback onContinue;

  String get _summary {
    final latestNote = record.latestProgressNote;
    if (latestNote != null) return latestNote.summary;

    return 'Henüz kayıtlı süreç notu yok.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = Colors.blue.shade700;
    final latestNote = record.latestProgressNote;
    final noteInfo = latestNote == null
        ? 'Henüz not kaydedilmedi'
        : '${record.progressNoteCount} not • Son not: ${formatDate(latestNote.createdAt)} ${formatTime(latestNote.createdAt)}';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: activeColor.withValues(alpha: 0.08),
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
                    color: activeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.pending_actions_rounded,
                    color: activeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Devam Eden Bakım',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        noteInfo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    record.statusLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: activeColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.tonalIcon(
                onPressed: onContinue,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Bakıma Devam Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceHistoryItem extends StatelessWidget {
  const _MaintenanceHistoryItem({
    required this.record,
    required this.formattedDate,
    required this.formatDate,
    required this.formatTime,
  });

  final MaintenanceRecord record;
  final String formattedDate;
  final String Function(DateTime date) formatDate;
  final String Function(DateTime date) formatTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completedColor = Colors.green.shade700;
    final latestNote = record.latestProgressNote;
    final hasNotes = record.hasProgressNotes;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: completedColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.check_rounded, color: completedColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: completedColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        record.statusLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: completedColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  hasNotes ? latestNote!.summary : 'Not eklenmedi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasNotes
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                if (record.photoCount > 0) ...[
                  const SizedBox(height: 8),
                  _PhotoCounterChip(count: record.photoCount),
                ],
                if (record.documentCount > 0) ...[
                  const SizedBox(height: 8),
                  _DocumentCounterChip(count: record.documentCount),
                ],
                if (hasNotes || record.plannedMaintenanceDate != null) ...[
                  const SizedBox(height: 8),
                  _MaintenanceDetailsExpansion(
                    record: record,
                    formatDate: formatDate,
                    formatTime: formatTime,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceDetailsExpansion extends StatelessWidget {
  const _MaintenanceDetailsExpansion({
    required this.record,
    required this.formatDate,
    required this.formatTime,
  });

  final MaintenanceRecord record;
  final String Function(DateTime date) formatDate;
  final String Function(DateTime date) formatTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressNotes = List<MaintenanceProgressNote>.of(
      record.effectiveProgressNotes,
    )..sort((first, second) => second.createdAt.compareTo(first.createdAt));

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text(
          progressNotes.isEmpty
              ? 'Tamamlama bilgilerini göster'
              : '${progressNotes.length} süreç notunu göster',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          if (record.plannedMaintenanceDate != null)
            _CompletionTimingCard(
              plannedDate: formatDate(record.plannedMaintenanceDate!),
              actualDate: formatDate(record.actualCompletionDate),
              delayText: record.delayLabel ?? 'Bilgi yok',
            ),
          ...progressNotes.map(
            (progressNote) => _ProgressNoteTimelineItem(
              note: progressNote,
              dateText: formatDate(progressNote.createdAt),
              timeText: formatTime(progressNote.createdAt),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionTimingCard extends StatelessWidget {
  const _CompletionTimingCard({
    required this.plannedDate,
    required this.actualDate,
    required this.delayText,
  });

  final String plannedDate;
  final String actualDate;
  final String delayText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tamamlama bilgileri',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _RecordDetailLine(
            label: 'Planlanan bakım tarihi',
            value: plannedDate,
          ),
          _RecordDetailLine(
            label: 'Gerçek tamamlanma tarihi',
            value: actualDate,
          ),
          _RecordDetailLine(label: 'Gecikme durumu', value: delayText),
        ],
      ),
    );
  }
}

class _ProgressNoteTimelineItem extends StatelessWidget {
  const _ProgressNoteTimelineItem({
    required this.note,
    required this.dateText,
    required this.timeText,
  });

  final MaintenanceProgressNote note;
  final String dateText;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 17,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '$dateText • $timeText',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          _RecordDetailLine(label: 'Bakım notu / Açıklama', value: note.note),
          _RecordDetailLine(
            label: 'Bugün yapılan işlem',
            value: note.todaysWork,
          ),
          _RecordDetailLine(
            label: 'Değişen parçalar',
            value: note.changedParts,
          ),
          _RecordDetailLine(
            label: 'Sonraki bakımda yapılacaklar',
            value: note.nextMaintenanceNotes,
          ),
          _RecordDetailLine(
            label: 'Genel durum notu',
            value: note.generalStatusNote,
          ),
          if (note.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Fotoğraflar',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            MaintenancePhotoGrid(photos: note.photos),
          ],
          if (note.documents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Belgeler',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            MaintenanceDocumentList(documents: note.documents),
          ],
        ],
      ),
    );
  }
}

class _PhotoCounterChip extends StatelessWidget {
  const _PhotoCounterChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '📷 $count Fotoğraf',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DocumentCounterChip extends StatelessWidget {
  const _DocumentCounterChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '📎 $count Belge',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecordDetailLine extends StatelessWidget {
  const _RecordDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

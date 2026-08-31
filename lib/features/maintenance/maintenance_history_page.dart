import 'package:flutter/material.dart';

import '../../models/maintenance_record.dart';
import '../../services/maintenance_service.dart';
import 'widgets/maintenance_document_widgets.dart';
import 'widgets/maintenance_photo_widgets.dart';

class MaintenanceHistoryPage extends StatefulWidget {
  const MaintenanceHistoryPage({super.key});

  @override
  State<MaintenanceHistoryPage> createState() => _MaintenanceHistoryPageState();
}

class _MaintenanceHistoryPageState extends State<MaintenanceHistoryPage> {
  final _searchController = TextEditingController();
  String _searchText = '';

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

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchText = '');
  }

  @override
  Widget build(BuildContext context) {
    final completedRecords = MaintenanceService.allRecords();
    final inProgressRecords = MaintenanceService.allInProgressRecords();
    final query = _searchText.trim().toLowerCase();

    bool matchesSearch(MaintenanceRecord record) {
      final searchableParts = <String?>[
        record.deviceName,
        record.note,
        record.todaysWork,
        record.changedParts,
        record.nextMaintenanceNotes,
        record.generalStatusNote,
        for (final progressNote in record.effectiveProgressNotes) ...[
          progressNote.note,
          progressNote.todaysWork,
          progressNote.changedParts,
          progressNote.nextMaintenanceNotes,
          progressNote.generalStatusNote,
          for (final document in progressNote.documents) document.fileName,
        ],
      ];
      final searchableText = searchableParts
          .whereType<String>()
          .join(' ')
          .toLowerCase();
      return searchableText.contains(query);
    }

    final filteredInProgressRecords = inProgressRecords
        .where(matchesSearch)
        .toList();
    final filteredCompletedRecords = completedRecords
        .where(matchesSearch)
        .toList();
    final hasRecords =
        completedRecords.isNotEmpty || inProgressRecords.isNotEmpty;
    final hasSearchResults =
        filteredCompletedRecords.isNotEmpty ||
        filteredInProgressRecords.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Bakım Geçmişi')),
      body: !hasRecords
          ? const _EmptyMaintenanceHistory()
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
                          _HistorySummary(
                            completedCount: completedRecords.length,
                            activeCount: inProgressRecords.length,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchText = value),
                            decoration: InputDecoration(
                              labelText: 'Bakım geçmişinde ara',
                              hintText:
                                  'Cihaz adı, bakım notu veya süreç detayı',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchText.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Aramayı temizle',
                                      onPressed: _clearSearch,
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: !hasSearchResults
                      ? _EmptySearchResult(onClear: _clearSearch)
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                              children: [
                                if (filteredInProgressRecords.isNotEmpty) ...[
                                  _HistorySectionHeader(
                                    title: 'Devam Eden Bakımlar',
                                    subtitle:
                                        'Henüz tamamlanmamış bakım süreçleri',
                                    count: filteredInProgressRecords.length,
                                  ),
                                  const SizedBox(height: 10),
                                  for (final record
                                      in filteredInProgressRecords) ...[
                                    _HistoryRecordCard(
                                      record: record,
                                      dateLabel: 'Son güncelleme',
                                      formattedDate: _formatDate(
                                        record.updatedAt,
                                      ),
                                      formatDate: _formatDate,
                                      formatTime: _formatTime,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                                if (filteredCompletedRecords.isNotEmpty) ...[
                                  if (filteredInProgressRecords.isNotEmpty)
                                    const SizedBox(height: 12),
                                  _HistorySectionHeader(
                                    title: 'Tamamlanan Bakımlar',
                                    subtitle:
                                        'Kapatılmış bakım geçmişi kayıtları',
                                    count: filteredCompletedRecords.length,
                                  ),
                                  const SizedBox(height: 10),
                                  for (final record
                                      in filteredCompletedRecords) ...[
                                    _HistoryRecordCard(
                                      record: record,
                                      dateLabel: 'Tamamlanma',
                                      formattedDate: _formatDate(
                                        record.completedDate,
                                      ),
                                      formatDate: _formatDate,
                                      formatTime: _formatTime,
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _HistorySectionHeader extends StatelessWidget {
  const _HistorySectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count kayıt',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.completedCount,
    required this.activeCount,
  });

  final int completedCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            child: Icon(Icons.history_rounded, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completedCount tamamlanmış bakım',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  activeCount == 0
                      ? 'Tüm cihazların bakım kayıtları'
                      : '$activeCount devam eden bakım ayrıca takip ediliyor',
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

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({
    required this.record,
    required this.dateLabel,
    required this.formattedDate,
    required this.formatDate,
    required this.formatTime,
  });

  final MaintenanceRecord record;
  final String dateLabel;
  final String formattedDate;
  final String Function(DateTime date) formatDate;
  final String Function(DateTime date) formatTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = record.isInProgress
        ? Colors.blue.shade700
        : Colors.green.shade700;
    final statusIcon = record.isInProgress
        ? Icons.pending_actions_rounded
        : Icons.task_alt_rounded;
    final dateIcon = record.isInProgress
        ? Icons.update_rounded
        : Icons.event_available_outlined;
    final latestNote = record.latestProgressNote;
    final hasNotes = record.hasProgressNotes;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(statusIcon, color: statusColor),
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
                          record.deviceName,
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
                          record.statusLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        dateIcon,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$dateLabel: $formattedDate',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    _HistoryPhotoCounterChip(count: record.photoCount),
                  ],
                  if (record.documentCount > 0) ...[
                    const SizedBox(height: 8),
                    _HistoryDocumentCounterChip(count: record.documentCount),
                  ],
                  if (hasNotes || record.plannedMaintenanceDate != null) ...[
                    const SizedBox(height: 8),
                    _HistoryDetailsExpansion(
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
      ),
    );
  }
}

class _HistoryDetailsExpansion extends StatelessWidget {
  const _HistoryDetailsExpansion({
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
            _HistoryCompletionTimingCard(
              plannedDate: formatDate(record.plannedMaintenanceDate!),
              actualDate: formatDate(record.actualCompletionDate),
              delayText: record.delayLabel ?? 'Bilgi yok',
            ),
          ...progressNotes.map(
            (progressNote) => _HistoryProgressNoteItem(
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

class _HistoryCompletionTimingCard extends StatelessWidget {
  const _HistoryCompletionTimingCard({
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
          _HistoryDetailLine(
            label: 'Planlanan bakım tarihi',
            value: plannedDate,
          ),
          _HistoryDetailLine(
            label: 'Gerçek tamamlanma tarihi',
            value: actualDate,
          ),
          _HistoryDetailLine(label: 'Gecikme durumu', value: delayText),
        ],
      ),
    );
  }
}

class _HistoryProgressNoteItem extends StatelessWidget {
  const _HistoryProgressNoteItem({
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
          _HistoryDetailLine(label: 'Bakım notu / Açıklama', value: note.note),
          _HistoryDetailLine(
            label: 'Bugün yapılan işlem',
            value: note.todaysWork,
          ),
          _HistoryDetailLine(
            label: 'Değişen parçalar',
            value: note.changedParts,
          ),
          _HistoryDetailLine(
            label: 'Sonraki bakımda yapılacaklar',
            value: note.nextMaintenanceNotes,
          ),
          _HistoryDetailLine(
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

class _HistoryPhotoCounterChip extends StatelessWidget {
  const _HistoryPhotoCounterChip({required this.count});

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

class _HistoryDocumentCounterChip extends StatelessWidget {
  const _HistoryDocumentCounterChip({required this.count});

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

class _HistoryDetailLine extends StatelessWidget {
  const _HistoryDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
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
          const SizedBox(height: 3),
          Text(value.trim(), style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyMaintenanceHistory extends StatelessWidget {
  const _EmptyMaintenanceHistory();

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
                Icons.history_toggle_off_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Bakım geçmişi henüz boş',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Devam eden ve tamamlanan cihaz bakımları burada en yeni kayıttan başlayarak gösterilir.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('Eşleşen bakım kaydı bulunamadı'),
          const SizedBox(height: 8),
          TextButton(onPressed: onClear, child: const Text('Aramayı temizle')),
        ],
      ),
    );
  }
}

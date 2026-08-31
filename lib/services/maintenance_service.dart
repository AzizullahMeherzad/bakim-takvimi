import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device.dart';
import '../models/maintenance_record.dart';
import 'device_service.dart';

class MaintenanceService {
  static const String _storageKey = 'maintenance_history';
  static final List<MaintenanceRecord> _records = [];

  static Future<void> loadRecords() async {
    final preferences = await SharedPreferences.getInstance();
    final jsonString = preferences.getString(_storageKey);

    _records.clear();
    if (jsonString == null || jsonString.isEmpty) return;

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      _records.addAll(
        decoded.map(
          (item) => MaintenanceRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Bakım geçmişi yüklenemedi: $error');
      debugPrintStack(stackTrace: stackTrace);
      _records.clear();
    }
  }

  static List<MaintenanceRecord> recordsForDevice(String deviceId) {
    final records =
        _records
            .where(
              (record) => record.deviceId == deviceId && record.isCompleted,
            )
            .toList()
          ..sort(
            (first, second) =>
                second.completedDate.compareTo(first.completedDate),
          );
    return List<MaintenanceRecord>.unmodifiable(records);
  }

  static MaintenanceRecord? activeRecordForDevice(String deviceId) {
    final records =
        _records
            .where(
              (record) => record.deviceId == deviceId && record.isInProgress,
            )
            .toList()
          ..sort(
            (first, second) => second.updatedAt.compareTo(first.updatedAt),
          );

    return records.isEmpty ? null : records.first;
  }

  static List<MaintenanceRecord> allRecords() {
    final records = _records.where((record) => record.isCompleted).toList()
      ..sort(
        (first, second) => second.completedDate.compareTo(first.completedDate),
      );
    return List<MaintenanceRecord>.unmodifiable(records);
  }

  static List<MaintenanceRecord> allInProgressRecords() {
    final records = _records.where((record) => record.isInProgress).toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return List<MaintenanceRecord>.unmodifiable(records);
  }

  static Future<MaintenanceRecord> saveMaintenanceDraft({
    required Device device,
    String? note,
    String? todaysWork,
    String? changedParts,
    String? nextMaintenanceNotes,
    String? generalStatusNote,
    List<MaintenancePhoto> photos = const [],
    List<MaintenanceDocument> documents = const [],
  }) async {
    final now = DateTime.now();
    final progressNote = _createProgressNote(
      deviceId: device.id,
      createdAt: now,
      note: note,
      todaysWork: todaysWork,
      changedParts: changedParts,
      nextMaintenanceNotes: nextMaintenanceNotes,
      generalStatusNote: generalStatusNote,
      photos: photos,
      documents: documents,
    );

    if (!progressNote.hasContent) {
      throw ArgumentError('Kaydedilecek yeni bir not girin.');
    }

    final existingRecord = activeRecordForDevice(device.id);
    final plannedMaintenanceDate =
        existingRecord?.plannedMaintenanceDate ?? device.nextMaintenanceDate;
    final progressNotes = [
      ...?existingRecord?.effectiveProgressNotes,
      progressNote,
    ];
    final record = MaintenanceRecord(
      id:
          existingRecord?.id ??
          '${device.id}-draft-${now.microsecondsSinceEpoch}',
      deviceId: device.id,
      deviceName: device.name,
      completedDate: existingRecord?.completedDate ?? now,
      note: _normalizedOptionalText(progressNote.note),
      todaysWork: progressNote.todaysWork,
      changedParts: progressNote.changedParts,
      nextMaintenanceNotes: progressNote.nextMaintenanceNotes,
      generalStatusNote: progressNote.generalStatusNote,
      status: MaintenanceRecordStatus.inProgress,
      updatedAt: now,
      plannedMaintenanceDate: plannedMaintenanceDate,
      progressNotes: progressNotes,
    );

    final previousRecords = List<MaintenanceRecord>.of(_records);
    _upsertRecord(record);
    _removeDuplicateActiveRecords(device.id, keepRecordId: record.id);

    try {
      await _saveRecords();
      return record;
    } catch (_) {
      _restoreRecords(previousRecords);
      rethrow;
    }
  }

  static Future<MaintenanceRecord?> removeDocumentFromActiveProgressNote({
    required String deviceId,
    required String progressNoteId,
    required String documentId,
  }) async {
    final existingRecord = activeRecordForDevice(deviceId);
    if (existingRecord == null) return null;

    final updatedProgressNotes = existingRecord.effectiveProgressNotes
        .map((progressNote) {
          if (progressNote.id != progressNoteId) return progressNote;

          return MaintenanceProgressNote(
            id: progressNote.id,
            createdAt: progressNote.createdAt,
            note: progressNote.note,
            todaysWork: progressNote.todaysWork,
            changedParts: progressNote.changedParts,
            nextMaintenanceNotes: progressNote.nextMaintenanceNotes,
            generalStatusNote: progressNote.generalStatusNote,
            photos: progressNote.photos,
            documents: progressNote.documents
                .where((document) => document.id != documentId)
                .toList(),
          );
        })
        .where((progressNote) => progressNote.hasContent)
        .toList();
    final now = DateTime.now();
    final updatedRecord = MaintenanceRecord(
      id: existingRecord.id,
      deviceId: existingRecord.deviceId,
      deviceName: existingRecord.deviceName,
      completedDate: existingRecord.completedDate,
      note: existingRecord.note,
      todaysWork: existingRecord.todaysWork,
      changedParts: existingRecord.changedParts,
      nextMaintenanceNotes: existingRecord.nextMaintenanceNotes,
      generalStatusNote: existingRecord.generalStatusNote,
      status: existingRecord.status,
      updatedAt: now,
      plannedMaintenanceDate: existingRecord.plannedMaintenanceDate,
      progressNotes: updatedProgressNotes,
    );

    final previousRecords = List<MaintenanceRecord>.of(_records);
    _upsertRecord(updatedRecord);

    try {
      await _saveRecords();
      return updatedRecord;
    } catch (_) {
      _restoreRecords(previousRecords);
      rethrow;
    }
  }

  static Future<Device> completeMaintenance({
    required Device device,
    String? note,
    String? todaysWork,
    String? changedParts,
    String? nextMaintenanceNotes,
    String? generalStatusNote,
    List<MaintenancePhoto> photos = const [],
    List<MaintenanceDocument> documents = const [],
  }) async {
    final completedDate = DateTime.now();
    final existingRecord = activeRecordForDevice(device.id);
    final plannedMaintenanceDate =
        existingRecord?.plannedMaintenanceDate ?? device.nextMaintenanceDate;
    final finalProgressNote = _createProgressNote(
      deviceId: device.id,
      createdAt: completedDate,
      note: note,
      todaysWork: todaysWork,
      changedParts: changedParts,
      nextMaintenanceNotes: nextMaintenanceNotes,
      generalStatusNote: generalStatusNote,
      photos: photos,
      documents: documents,
    );
    final progressNotes = [
      ...?existingRecord?.effectiveProgressNotes,
      if (finalProgressNote.hasContent) finalProgressNote,
    ];
    final latestProgressNote = progressNotes.isEmpty
        ? null
        : progressNotes.last;
    final record = MaintenanceRecord(
      id:
          existingRecord?.id ??
          '${device.id}-${completedDate.microsecondsSinceEpoch}',
      deviceId: device.id,
      deviceName: device.name,
      completedDate: completedDate,
      note: _normalizedOptionalText(latestProgressNote?.note),
      todaysWork: latestProgressNote?.todaysWork ?? '',
      changedParts: latestProgressNote?.changedParts ?? '',
      nextMaintenanceNotes: latestProgressNote?.nextMaintenanceNotes ?? '',
      generalStatusNote: latestProgressNote?.generalStatusNote ?? '',
      status: MaintenanceRecordStatus.completed,
      updatedAt: completedDate,
      plannedMaintenanceDate: plannedMaintenanceDate,
      progressNotes: progressNotes,
    );
    final nextMaintenanceBaseDate =
        device.maintenanceCalculationMethod ==
            MaintenanceCalculationMethod.completionDate
        ? completedDate
        : plannedMaintenanceDate;
    final updatedDevice = Device(
      id: device.id,
      name: device.name,
      category: device.category,
      serialNumber: device.serialNumber,
      location: device.location,
      lastMaintenanceDate: nextMaintenanceBaseDate,
      maintenanceIntervalMonths: device.maintenanceIntervalMonths,
      maintenanceCalculationMethod: device.maintenanceCalculationMethod,
      documentPath: device.documentPath,
    );

    final previousRecords = List<MaintenanceRecord>.of(_records);
    _upsertRecord(record);
    _removeDuplicateActiveRecords(device.id, keepRecordId: record.id);

    try {
      await _saveRecords();
      await DeviceService.updateDevice(updatedDevice);
      return updatedDevice;
    } catch (_) {
      _restoreRecords(previousRecords);
      await _saveRecords();
      rethrow;
    }
  }

  static String _normalizedText(String? value) {
    return value?.trim() ?? '';
  }

  static String? _normalizedOptionalText(String? value) {
    final normalizedValue = value?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) return null;
    return normalizedValue;
  }

  static MaintenanceProgressNote _createProgressNote({
    required String deviceId,
    required DateTime createdAt,
    String? note,
    String? todaysWork,
    String? changedParts,
    String? nextMaintenanceNotes,
    String? generalStatusNote,
    List<MaintenancePhoto> photos = const [],
    List<MaintenanceDocument> documents = const [],
  }) {
    return MaintenanceProgressNote(
      id: '$deviceId-progress-${createdAt.microsecondsSinceEpoch}',
      createdAt: createdAt,
      note: _normalizedText(note),
      todaysWork: _normalizedText(todaysWork),
      changedParts: _normalizedText(changedParts),
      nextMaintenanceNotes: _normalizedText(nextMaintenanceNotes),
      generalStatusNote: _normalizedText(generalStatusNote),
      photos: List<MaintenancePhoto>.unmodifiable(photos),
      documents: List<MaintenanceDocument>.unmodifiable(documents),
    );
  }

  static void _upsertRecord(MaintenanceRecord record) {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      _records.add(record);
      return;
    }

    _records[index] = record;
  }

  static void _removeDuplicateActiveRecords(
    String deviceId, {
    required String keepRecordId,
  }) {
    _records.removeWhere(
      (record) =>
          record.deviceId == deviceId &&
          record.isInProgress &&
          record.id != keepRecordId,
    );
  }

  static void _restoreRecords(List<MaintenanceRecord> previousRecords) {
    _records
      ..clear()
      ..addAll(previousRecords);
  }

  static Future<void> _saveRecords() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _records.map((record) => record.toJson()).toList(),
    );
    await preferences.setString(_storageKey, encoded);
  }
}

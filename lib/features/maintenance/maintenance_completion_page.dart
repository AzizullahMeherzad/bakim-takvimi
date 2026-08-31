import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/device.dart';
import '../../models/maintenance_record.dart';
import '../../services/maintenance_service.dart';
import 'widgets/maintenance_document_widgets.dart';
import 'widgets/maintenance_photo_widgets.dart';

class MaintenanceCompletionResult {
  const MaintenanceCompletionResult._({
    this.updatedDevice,
    required this.savedAsDraft,
  });

  final Device? updatedDevice;
  final bool savedAsDraft;

  const MaintenanceCompletionResult.draftSaved() : this._(savedAsDraft: true);

  const MaintenanceCompletionResult.completed(Device updatedDevice)
    : this._(updatedDevice: updatedDevice, savedAsDraft: false);
}

class MaintenanceCompletionPage extends StatefulWidget {
  const MaintenanceCompletionPage({super.key, required this.device});

  final Device device;

  @override
  State<MaintenanceCompletionPage> createState() =>
      _MaintenanceCompletionPageState();
}

class _MaintenanceCompletionPageState extends State<MaintenanceCompletionPage> {
  final _noteController = TextEditingController();
  final _todaysWorkController = TextEditingController();
  final _changedPartsController = TextEditingController();
  final _nextMaintenanceNotesController = TextEditingController();
  final _generalStatusNoteController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<MaintenancePhoto> _selectedPhotos = [];
  final List<MaintenanceDocument> _selectedDocuments = [];
  final Map<String, String> _selectedDocumentSourcePaths = {};

  late MaintenanceRecord? _activeRecord;
  late String _lastSavedSignature;

  bool _isSavingDraft = false;
  bool _isCompleting = false;
  bool _discardConfirmed = false;
  int _photoSequence = 0;
  int _documentSequence = 0;
  String? _errorMessage;

  bool get _isBusy => _isSavingDraft || _isCompleting;

  @override
  void initState() {
    super.initState();
    _activeRecord = MaintenanceService.activeRecordForDevice(widget.device.id);
    _lastSavedSignature = _currentSignature;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _todaysWorkController.dispose();
    _changedPartsController.dispose();
    _nextMaintenanceNotesController.dispose();
    _generalStatusNoteController.dispose();
    super.dispose();
  }

  String get _currentSignature {
    return [
      _noteController.text.trim(),
      _todaysWorkController.text.trim(),
      _changedPartsController.text.trim(),
      _nextMaintenanceNotesController.text.trim(),
      _generalStatusNoteController.text.trim(),
      _selectedPhotos.map((photo) => photo.path).join('|'),
      _selectedDocuments.map((document) => document.filePath).join('|'),
    ].join('\n---\n');
  }

  bool get _hasUnsavedChanges => _currentSignature != _lastSavedSignature;

  bool get _hasNewNoteContent {
    return _noteController.text.trim().isNotEmpty ||
        _todaysWorkController.text.trim().isNotEmpty ||
        _changedPartsController.text.trim().isNotEmpty ||
        _nextMaintenanceNotesController.text.trim().isNotEmpty ||
        _generalStatusNoteController.text.trim().isNotEmpty ||
        _selectedPhotos.isNotEmpty ||
        _selectedDocuments.isNotEmpty;
  }

  List<MaintenanceProgressNote> get _previousNotes {
    final notes = _activeRecord?.effectiveProgressNotes ?? const [];
    return List<MaintenanceProgressNote>.of(notes)
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
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

  void _clearNewNoteFields() {
    _noteController.clear();
    _todaysWorkController.clear();
    _changedPartsController.clear();
    _nextMaintenanceNotesController.clear();
    _generalStatusNoteController.clear();
    _selectedPhotos.clear();
    _selectedDocuments.clear();
    _selectedDocumentSourcePaths.clear();
  }

  String _photoNameFromPath(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    return name.isEmpty ? 'maintenance-photo.jpg' : name;
  }

  MaintenancePhoto _photoFromXFile(XFile file) {
    final now = DateTime.now();
    _photoSequence++;

    return MaintenancePhoto(
      id: '${widget.device.id}-photo-${now.microsecondsSinceEpoch}-$_photoSequence',
      path: file.path,
      name: file.name.isEmpty ? _photoNameFromPath(file.path) : file.name,
      createdAt: now,
    );
  }

  void _showPickerMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isPermissionDenied(PlatformException error) {
    final code = error.code.toLowerCase();
    return code.contains('denied') ||
        code.contains('restricted') ||
        code.contains('permission');
  }

  void _addPickedPhotos(List<XFile> files) {
    if (files.isEmpty || !mounted) return;

    setState(() {
      _errorMessage = null;
      _selectedPhotos.addAll(files.map(_photoFromXFile));
    });
  }

  Future<void> _pickCameraPhoto() async {
    if (_isBusy) return;

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) return;
      _addPickedPhotos([photo]);
    } on PlatformException catch (error) {
      if (_isPermissionDenied(error)) {
        _showPickerMessage(
          'Kamera izni verilmedi. Lütfen cihaz ayarlarından kamera iznini açın.',
        );
        return;
      }
      _showPickerMessage('Fotoğraf çekilemedi. Lütfen tekrar deneyin.');
    } catch (_) {
      _showPickerMessage('Fotoğraf çekilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<List<XFile>> _pickSingleGalleryImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return image == null ? <XFile>[] : <XFile>[image];
  }

  Future<void> _pickGalleryPhotos() async {
    if (_isBusy) return;

    try {
      final photos = await _imagePicker.pickMultiImage(imageQuality: 85);
      _addPickedPhotos(photos);
    } on UnimplementedError {
      final photos = await _pickSingleGalleryImage();
      _addPickedPhotos(photos);
    } on PlatformException catch (error) {
      if (_isPermissionDenied(error)) {
        _showPickerMessage(
          'Galeri izni verilmedi. Lütfen cihaz ayarlarından fotoğraf iznini açın.',
        );
        return;
      }

      try {
        final photos = await _pickSingleGalleryImage();
        _addPickedPhotos(photos);
      } catch (_) {
        _showPickerMessage('Galeriden fotoğraf seçilemedi.');
      }
    } catch (_) {
      _showPickerMessage('Galeriden fotoğraf seçilemedi.');
    }
  }

  void _removeSelectedPhoto(MaintenancePhoto photo) {
    if (_isBusy) return;

    setState(() {
      _selectedPhotos.removeWhere((item) => item.id == photo.id);
    });
  }

  String _extensionFromFileName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return '';
    return parts.last.trim().toLowerCase();
  }

  bool _isSupportedDocumentExtension(String extension) {
    final normalizedExtension = extension.trim().toLowerCase();
    return normalizedExtension == 'pdf' ||
        normalizedExtension == 'doc' ||
        normalizedExtension == 'docx';
  }

  String _safeDocumentStem(String fileName) {
    final extension = _extensionFromFileName(fileName);
    final nameWithoutExtension = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length - 1);
    final safeName = nameWithoutExtension
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safeName.isEmpty ? 'maintenance-document' : safeName;
  }

  Future<Directory> _maintenanceDocumentsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}maintenance_documents',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  String _storedDocumentFileName({
    required String originalFileName,
    required String extension,
    required DateTime now,
  }) {
    _documentSequence++;
    final safeStem = _safeDocumentStem(originalFileName);
    return '${widget.device.id}_${now.microsecondsSinceEpoch}_$_documentSequence'
        '_$safeStem.$extension';
  }

  Future<MaintenanceDocument?> _copyPickedDocument(fp.PlatformFile file) async {
    final sourcePath = file.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      _showPickerMessage('Belge yolu okunamadı.');
      return null;
    }

    final extension = (file.extension ?? _extensionFromFileName(file.name))
        .trim()
        .toLowerCase();
    if (!_isSupportedDocumentExtension(extension)) {
      _showPickerMessage('Yalnızca PDF, DOC ve DOCX belgeleri eklenebilir.');
      return null;
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      _showPickerMessage('Dosya cihazda bulunamadı.');
      return null;
    }

    try {
      final now = DateTime.now();
      final targetDirectory = await _maintenanceDocumentsDirectory();
      final targetFileName = _storedDocumentFileName(
        originalFileName: file.name,
        extension: extension,
        now: now,
      );
      final targetFile = File(
        '${targetDirectory.path}${Platform.pathSeparator}$targetFileName',
      );
      final copiedFile = await sourceFile.copy(targetFile.path);

      return MaintenanceDocument(
        id: '${widget.device.id}-document-${now.microsecondsSinceEpoch}-$_documentSequence',
        fileName: file.name.isEmpty ? targetFileName : file.name,
        filePath: copiedFile.path,
        extension: extension,
        addedAt: now,
      );
    } catch (_) {
      _showPickerMessage('Belge kopyalanamadı. Lütfen tekrar deneyin.');
      return null;
    }
  }

  Future<void> _pickDocuments() async {
    if (_isBusy) return;

    try {
      final result = await fp.FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: fp.FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final copiedDocuments = <MaintenanceDocument>[];
      final copiedSourcePaths = <String, String>{};
      var skippedDuplicateCount = 0;

      for (final file in result.files) {
        final sourcePath = file.path?.trim();
        final normalizedSourcePath = sourcePath?.toLowerCase();
        final extension = (file.extension ?? _extensionFromFileName(file.name))
            .trim()
            .toLowerCase();
        final alreadySelectedByPath =
            normalizedSourcePath != null &&
            _selectedDocumentSourcePaths.containsValue(normalizedSourcePath);
        final alreadySelectedByName = _selectedDocuments.any(
          (document) =>
              document.fileName == file.name && document.extension == extension,
        );

        if (alreadySelectedByPath || alreadySelectedByName) {
          skippedDuplicateCount++;
          continue;
        }

        final copiedDocument = await _copyPickedDocument(file);
        if (copiedDocument == null) continue;

        copiedDocuments.add(copiedDocument);
        if (normalizedSourcePath != null) {
          copiedSourcePaths[copiedDocument.id] = normalizedSourcePath;
        }
      }

      if (!mounted) return;
      if (copiedDocuments.isNotEmpty) {
        setState(() {
          _errorMessage = null;
          _selectedDocuments.addAll(copiedDocuments);
          _selectedDocumentSourcePaths.addAll(copiedSourcePaths);
        });
      }

      if (skippedDuplicateCount > 0) {
        _showPickerMessage('Aynı belge tekrar eklenmedi.');
      }
    } catch (_) {
      _showPickerMessage('Belge seçilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _removeSelectedDocument(MaintenanceDocument document) async {
    if (_isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Belge kaldırılsın mı?'),
        content: const Text(
          'Bu belge bakım kaydından kaldırılacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _selectedDocuments.removeWhere((item) => item.id == document.id);
      _selectedDocumentSourcePaths.remove(document.id);
    });

    try {
      final file = File(document.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Belge dosyası silinemese bile bakım akışı kesilmemeli.
    }
  }

  Future<void> _removeSavedDocument(
    MaintenanceProgressNote progressNote,
    MaintenanceDocument document,
  ) async {
    if (_isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Belge kaldırılsın mı?'),
        content: const Text(
          'Bu belge bakım kaydından kaldırılacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      final updatedRecord =
          await MaintenanceService.removeDocumentFromActiveProgressNote(
            deviceId: widget.device.id,
            progressNoteId: progressNote.id,
            documentId: document.id,
          );

      if (!mounted) return;
      setState(() => _activeRecord = updatedRecord);

      try {
        final file = File(document.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Belge dosyası silinemese bile bakım akışı kesilmemeli.
      }
    } catch (_) {
      if (!mounted) return;
      _showPickerMessage('Belge kaldırılamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (_isBusy) return false;
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Yeni not kaydedilmedi'),
        content: const Text(
          'Kaydedilmemiş yeni not var. Çıkmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _closeWithoutSaving() async {
    final canClose = await _confirmDiscardIfNeeded();
    if (!mounted || !canClose) return;
    setState(() => _discardConfirmed = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  Future<void> _saveDraft() async {
    if (_isBusy) return;

    if (!_hasNewNoteContent) {
      setState(() {
        _errorMessage = 'Kaydedilecek yeni bir not girin.';
      });
      return;
    }

    setState(() {
      _isSavingDraft = true;
      _errorMessage = null;
    });

    try {
      await MaintenanceService.saveMaintenanceDraft(
        device: widget.device,
        note: _noteController.text,
        todaysWork: _todaysWorkController.text,
        changedParts: _changedPartsController.text,
        nextMaintenanceNotes: _nextMaintenanceNotesController.text,
        generalStatusNote: _generalStatusNoteController.text,
        photos: _selectedPhotos,
        documents: _selectedDocuments,
      );

      if (!mounted) return;
      _clearNewNoteFields();
      _lastSavedSignature = _currentSignature;
      setState(() {
        _isSavingDraft = false;
        _discardConfirmed = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pop(const MaintenanceCompletionResult.draftSaved());
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSavingDraft = false;
        _errorMessage = 'Bakım notu kaydedilemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  Future<void> _completeMaintenance() async {
    if (_isBusy) return;

    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });

    try {
      final updatedDevice = await MaintenanceService.completeMaintenance(
        device: widget.device,
        note: _noteController.text,
        todaysWork: _todaysWorkController.text,
        changedParts: _changedPartsController.text,
        nextMaintenanceNotes: _nextMaintenanceNotesController.text,
        generalStatusNote: _generalStatusNoteController.text,
        photos: _selectedPhotos,
        documents: _selectedDocuments,
      );

      if (!mounted) return;
      _clearNewNoteFields();
      _lastSavedSignature = _currentSignature;
      setState(() {
        _isCompleting = false;
        _discardConfirmed = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pop(MaintenanceCompletionResult.completed(updatedDevice));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCompleting = false;
        _errorMessage = 'Bakım kaydı oluşturulamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasActiveRecord = _activeRecord != null;
    final startedDate = _activeRecord?.completedDate ?? DateTime.now();
    final previousNotes = _previousNotes;

    return PopScope<MaintenanceCompletionResult?>(
      canPop: !_isBusy && (!_hasUnsavedChanges || _discardConfirmed),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _closeWithoutSaving();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(hasActiveRecord ? 'Bakıma Devam Et' : 'Bakımı Başlat'),
          leading: IconButton(
            tooltip: 'Kapat',
            onPressed: _isBusy ? null : _closeWithoutSaving,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
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
                      _FormSection(
                        title: 'Bakım Süreci',
                        icon: hasActiveRecord
                            ? Icons.pending_actions_rounded
                            : Icons.playlist_add_check_rounded,
                        children: [
                          _ProcessInfoRow(
                            label: 'Cihaz',
                            value: widget.device.name,
                          ),
                          _ProcessInfoRow(
                            label: 'Durum',
                            value: hasActiveRecord
                                ? 'Devam Ediyor'
                                : 'Yeni bakım başlatılıyor',
                          ),
                          _ProcessInfoRow(
                            label: 'Başlangıç',
                            value:
                                '${_formatDate(startedDate)} ${_formatTime(startedDate)}',
                          ),
                          if (previousNotes.isNotEmpty)
                            _ProcessInfoRow(
                              label: 'Kaydedilen not',
                              value: '${previousNotes.length} adet',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Önceki Notlar',
                        icon: Icons.timeline_rounded,
                        children: [
                          Text(
                            'Kaydettiğiniz her not tarih ve saat bilgisiyle bakım sürecine eklenir.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                          if (previousNotes.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                'Henüz kaydedilmiş bakım notu yok.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            )
                          else
                            ...List.generate(previousNotes.length, (index) {
                              final progressNote = previousNotes[index];
                              return Column(
                                children: [
                                  _ProgressNoteCard(
                                    note: progressNote,
                                    dateText: _formatDate(
                                      progressNote.createdAt,
                                    ),
                                    timeText: _formatTime(
                                      progressNote.createdAt,
                                    ),
                                    onRemoveDocument: (document) =>
                                        _removeSavedDocument(
                                          progressNote,
                                          document,
                                        ),
                                  ),
                                  if (index < previousNotes.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              );
                            }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Yeni Not Ekle',
                        icon: Icons.edit_note_rounded,
                        children: [
                          _MaintenanceTextField(
                            controller: _noteController,
                            enabled: !_isBusy,
                            label: 'Bakım notu / Açıklama',
                            hint:
                                'Bakımın genel özeti, gözlem veya açıklamalar',
                            maxLength: 700,
                            minLines: 3,
                          ),
                          const SizedBox(height: 12),
                          _MaintenanceTextField(
                            controller: _todaysWorkController,
                            enabled: !_isBusy,
                            label: 'Bugün yapılan işlem',
                            hint: 'Temizlik, kontrol, kalibrasyon, onarım vb.',
                            maxLength: 500,
                            minLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _MaintenanceTextField(
                            controller: _changedPartsController,
                            enabled: !_isBusy,
                            label: 'Değişen parçalar',
                            hint: 'Parça adı, adet veya kısa açıklama',
                            maxLength: 500,
                            minLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _MaintenanceTextField(
                            controller: _nextMaintenanceNotesController,
                            enabled: !_isBusy,
                            label: 'Sonraki bakımda yapılacaklar',
                            hint:
                                'Bir sonraki bakımda takip edilecek işler veya uyarılar',
                            maxLength: 500,
                            minLines: 2,
                          ),
                          const SizedBox(height: 12),
                          _MaintenanceTextField(
                            controller: _generalStatusNoteController,
                            enabled: !_isBusy,
                            label: 'Genel durum notu',
                            hint: 'Cihazın bakım sürecindeki genel durumu',
                            maxLength: 500,
                            minLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Fotoğraflar',
                        icon: Icons.photo_camera_outlined,
                        children: [
                          Text(
                            'Fotoğraflar yalnızca şu anda kaydedeceğiniz bakım notuna eklenir.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 560;
                              final cameraButton = FilledButton.tonalIcon(
                                onPressed: _isBusy ? null : _pickCameraPhoto,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Fotoğraf Çek'),
                              );
                              final galleryButton = OutlinedButton.icon(
                                onPressed: _isBusy ? null : _pickGalleryPhotos,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Galeriden Seç'),
                              );

                              if (compact) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: 48, child: cameraButton),
                                    const SizedBox(height: 10),
                                    SizedBox(height: 48, child: galleryButton),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: cameraButton,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: galleryButton,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          MaintenancePhotoGrid(
                            photos: _selectedPhotos,
                            onRemove: _removeSelectedPhoto,
                            emptyText:
                                'Bu yeni bakım notu için henüz fotoğraf seçilmedi.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Belgeler',
                        icon: Icons.attach_file_rounded,
                        children: [
                          Text(
                            'PDF, DOC ve DOCX belgeleri bu yeni bakım notuyla birlikte saklanır.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isBusy ? null : _pickDocuments,
                              icon: const Icon(Icons.note_add_outlined),
                              label: const Text('Belge Ekle'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          MaintenanceDocumentList(
                            documents: _selectedDocuments,
                            onRemove: _removeSelectedDocument,
                            emptyText:
                                'Bu yeni bakım notu için henüz belge seçilmedi.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Tamamlama',
                        icon: Icons.verified_outlined,
                        children: [
                          Text(
                            'Bakım henüz bitmediyse yeni notu kaydedin. Tüm işlemler tamamlandığında bakımı kapatın.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                    ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 620;
                              final saveButton = FilledButton.tonalIcon(
                                onPressed: _isBusy ? null : _saveDraft,
                                icon: _isSavingDraft
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(
                                  _isSavingDraft
                                      ? 'Kaydediliyor...'
                                      : 'Notu Kaydet',
                                ),
                              );
                              final completeButton = FilledButton.icon(
                                onPressed: _isBusy
                                    ? null
                                    : _completeMaintenance,
                                icon: _isCompleting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded),
                                label: Text(
                                  _isCompleting
                                      ? 'Tamamlanıyor...'
                                      : 'Bakımı Tamamla',
                                ),
                              );

                              if (compact) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: 52, child: saveButton),
                                    const SizedBox(height: 10),
                                    SizedBox(height: 52, child: completeButton),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 52,
                                      child: saveButton,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 52,
                                      child: completeButton,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: _isBusy ? null : _closeWithoutSaving,
                              child: const Text('Vazgeç'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessInfoRow extends StatelessWidget {
  const _ProcessInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
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
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressNoteCard extends StatelessWidget {
  const _ProgressNoteCard({
    required this.note,
    required this.dateText,
    required this.timeText,
    this.onRemoveDocument,
  });

  final MaintenanceProgressNote note;
  final String dateText;
  final String timeText;
  final ValueChanged<MaintenanceDocument>? onRemoveDocument;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
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
          const SizedBox(height: 10),
          _ProgressNoteLine(label: 'Bakım notu / Açıklama', value: note.note),
          _ProgressNoteLine(
            label: 'Bugün yapılan işlem',
            value: note.todaysWork,
          ),
          _ProgressNoteLine(
            label: 'Değişen parçalar',
            value: note.changedParts,
          ),
          _ProgressNoteLine(
            label: 'Sonraki bakımda yapılacaklar',
            value: note.nextMaintenanceNotes,
          ),
          _ProgressNoteLine(
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
            MaintenanceDocumentList(
              documents: note.documents,
              onRemove: onRemoveDocument,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressNoteLine extends StatelessWidget {
  const _ProgressNoteLine({required this.label, required this.value});

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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MaintenanceTextField extends StatelessWidget {
  const _MaintenanceTextField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.minLines,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final int maxLength;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: minLines + 2,
      maxLength: maxLength,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
    );
  }
}

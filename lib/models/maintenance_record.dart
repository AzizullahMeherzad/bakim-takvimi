enum MaintenanceRecordStatus {
  inProgress,
  completed;

  String get storageValue {
    return switch (this) {
      MaintenanceRecordStatus.inProgress => 'inProgress',
      MaintenanceRecordStatus.completed => 'completed',
    };
  }

  String get label {
    return switch (this) {
      MaintenanceRecordStatus.inProgress => 'Devam Ediyor',
      MaintenanceRecordStatus.completed => 'Tamamlandı',
    };
  }

  static MaintenanceRecordStatus fromStorageValue(String? value) {
    return switch (value) {
      'inProgress' => MaintenanceRecordStatus.inProgress,
      _ => MaintenanceRecordStatus.completed,
    };
  }
}

class MaintenancePhoto {
  const MaintenancePhoto({
    required this.id,
    required this.path,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String path;
  final String name;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MaintenancePhoto.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'] as String?;
    final createdAt = createdAtValue == null
        ? DateTime.now()
        : DateTime.parse(createdAtValue);
    final path = (json['path'] as String?) ?? '';

    return MaintenancePhoto(
      id:
          (json['id'] as String?) ??
          'photo-${createdAt.microsecondsSinceEpoch}',
      path: path,
      name: (json['name'] as String?) ?? path.split(RegExp(r'[\\/]')).last,
      createdAt: createdAt,
    );
  }
}

class MaintenanceDocument {
  const MaintenanceDocument({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.extension,
    required this.addedAt,
  });

  final String id;
  final String fileName;
  final String filePath;
  final String extension;
  final DateTime addedAt;

  bool get isPdf => extension.toLowerCase() == 'pdf';

  bool get isWord {
    final normalizedExtension = extension.toLowerCase();
    return normalizedExtension == 'doc' || normalizedExtension == 'docx';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'extension': extension,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory MaintenanceDocument.fromJson(Map<String, dynamic> json) {
    final addedAtValue = json['addedAt'] as String?;
    final addedAt = addedAtValue == null
        ? DateTime.now()
        : DateTime.tryParse(addedAtValue) ?? DateTime.now();
    final filePath = (json['filePath'] as String?) ?? '';
    final fallbackName = filePath.split(RegExp(r'[\\/]')).last;
    final fileName =
        (json['fileName'] as String?) ??
        (fallbackName.isEmpty ? 'Belge' : fallbackName);
    final extensionFromName = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final extensionFromPath = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : '';
    final extension = ((json['extension'] as String?) ?? extensionFromName)
        .trim()
        .toLowerCase();

    return MaintenanceDocument(
      id:
          (json['id'] as String?) ??
          'document-${addedAt.microsecondsSinceEpoch}',
      fileName: fileName,
      filePath: filePath,
      extension: extension.isEmpty ? extensionFromPath : extension,
      addedAt: addedAt,
    );
  }
}

class MaintenanceProgressNote {
  const MaintenanceProgressNote({
    required this.id,
    required this.createdAt,
    this.note = '',
    this.todaysWork = '',
    this.changedParts = '',
    this.nextMaintenanceNotes = '',
    this.generalStatusNote = '',
    this.photos = const [],
    this.documents = const [],
  });

  final String id;
  final DateTime createdAt;
  final String note;
  final String todaysWork;
  final String changedParts;
  final String nextMaintenanceNotes;
  final String generalStatusNote;
  final List<MaintenancePhoto> photos;
  final List<MaintenanceDocument> documents;

  bool get hasContent {
    return note.trim().isNotEmpty ||
        todaysWork.trim().isNotEmpty ||
        changedParts.trim().isNotEmpty ||
        nextMaintenanceNotes.trim().isNotEmpty ||
        generalStatusNote.trim().isNotEmpty ||
        photos.isNotEmpty ||
        documents.isNotEmpty;
  }

  bool get hasDetails {
    return todaysWork.trim().isNotEmpty ||
        changedParts.trim().isNotEmpty ||
        nextMaintenanceNotes.trim().isNotEmpty ||
        generalStatusNote.trim().isNotEmpty;
  }

  int get photoCount => photos.length;

  int get documentCount => documents.length;

  String get summary {
    final todaysWorkText = todaysWork.trim();
    if (todaysWorkText.isNotEmpty) return todaysWorkText;

    final noteText = note.trim();
    if (noteText.isNotEmpty) return noteText;

    final changedPartsText = changedParts.trim();
    if (changedPartsText.isNotEmpty) return changedPartsText;

    final nextMaintenanceText = nextMaintenanceNotes.trim();
    if (nextMaintenanceText.isNotEmpty) return nextMaintenanceText;

    final generalStatusText = generalStatusNote.trim();
    if (generalStatusText.isNotEmpty) return generalStatusText;

    if (photos.isNotEmpty) return 'Fotoğraf eklendi';
    if (documents.isNotEmpty) return 'Belge eklendi';

    return 'Not eklenmedi';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
      'todaysWork': todaysWork,
      'changedParts': changedParts,
      'nextMaintenanceNotes': nextMaintenanceNotes,
      'generalStatusNote': generalStatusNote,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'documents': documents.map((document) => document.toJson()).toList(),
    };
  }

  factory MaintenanceProgressNote.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'] as String?;
    final createdAt = createdAtValue == null
        ? DateTime.now()
        : DateTime.parse(createdAtValue);
    final photosJson = json['photos'];
    final photos = photosJson is List
        ? photosJson
              .map(
                (item) => MaintenancePhoto.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .where((photo) => photo.path.trim().isNotEmpty)
              .toList()
        : <MaintenancePhoto>[];
    final documentsJson = json['documents'];
    final documents = documentsJson is List
        ? documentsJson
              .map(
                (item) => MaintenanceDocument.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .where((document) => document.filePath.trim().isNotEmpty)
              .toList()
        : <MaintenanceDocument>[];

    return MaintenanceProgressNote(
      id:
          (json['id'] as String?) ??
          'progress-${createdAt.microsecondsSinceEpoch}',
      createdAt: createdAt,
      note: (json['note'] as String?) ?? '',
      todaysWork: (json['todaysWork'] as String?) ?? '',
      changedParts: (json['changedParts'] as String?) ?? '',
      nextMaintenanceNotes: (json['nextMaintenanceNotes'] as String?) ?? '',
      generalStatusNote: (json['generalStatusNote'] as String?) ?? '',
      photos: photos,
      documents: documents,
    );
  }
}

class MaintenanceRecord {
  MaintenanceRecord({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.completedDate,
    this.note,
    this.todaysWork = '',
    this.changedParts = '',
    this.nextMaintenanceNotes = '',
    this.generalStatusNote = '',
    this.status = MaintenanceRecordStatus.completed,
    DateTime? updatedAt,
    this.plannedMaintenanceDate,
    List<MaintenanceProgressNote> progressNotes = const [],
  }) : updatedAt = updatedAt ?? completedDate,
       progressNotes = List<MaintenanceProgressNote>.unmodifiable(
         progressNotes.where((note) => note.hasContent),
       );

  final String id;
  final String deviceId;
  final String deviceName;
  final DateTime completedDate;
  final String? note;
  final String todaysWork;
  final String changedParts;
  final String nextMaintenanceNotes;
  final String generalStatusNote;
  final MaintenanceRecordStatus status;
  final DateTime updatedAt;
  final DateTime? plannedMaintenanceDate;
  final List<MaintenanceProgressNote> progressNotes;

  String get statusLabel => status.label;

  bool get isInProgress => status == MaintenanceRecordStatus.inProgress;

  bool get isCompleted => status == MaintenanceRecordStatus.completed;

  List<MaintenanceProgressNote> get effectiveProgressNotes {
    if (progressNotes.isNotEmpty) return progressNotes;

    final legacyNote = legacyProgressNote;
    if (legacyNote == null) return const [];

    return List<MaintenanceProgressNote>.unmodifiable([legacyNote]);
  }

  MaintenanceProgressNote? get legacyProgressNote {
    final legacyNote = MaintenanceProgressNote(
      id: '$id-legacy-progress-note',
      createdAt: updatedAt,
      note: note ?? '',
      todaysWork: todaysWork,
      changedParts: changedParts,
      nextMaintenanceNotes: nextMaintenanceNotes,
      generalStatusNote: generalStatusNote,
    );

    return legacyNote.hasContent ? legacyNote : null;
  }

  MaintenanceProgressNote? get latestProgressNote {
    final notes = effectiveProgressNotes;
    if (notes.isEmpty) return null;

    return notes.reduce(
      (latest, note) =>
          note.createdAt.isAfter(latest.createdAt) ? note : latest,
    );
  }

  int get progressNoteCount => effectiveProgressNotes.length;

  bool get hasProgressNotes => effectiveProgressNotes.isNotEmpty;

  int get photoCount {
    return effectiveProgressNotes.fold<int>(
      0,
      (total, note) => total + note.photoCount,
    );
  }

  int get documentCount {
    return effectiveProgressNotes.fold<int>(
      0,
      (total, note) => total + note.documentCount,
    );
  }

  DateTime get actualCompletionDate => completedDate;

  int? get delayInDays {
    final plannedDate = plannedMaintenanceDate;
    if (plannedDate == null) return null;

    final plannedOnly = DateTime(
      plannedDate.year,
      plannedDate.month,
      plannedDate.day,
    );
    final completedOnly = DateTime(
      actualCompletionDate.year,
      actualCompletionDate.month,
      actualCompletionDate.day,
    );

    return completedOnly.difference(plannedOnly).inDays;
  }

  String? get delayLabel {
    final delay = delayInDays;
    if (delay == null) return null;
    if (delay == 0) return 'Zamanında tamamlandı';
    if (delay > 0) return '$delay gün gecikti';

    return '${delay.abs()} gün erken tamamlandı';
  }

  bool get hasDetails {
    return todaysWork.trim().isNotEmpty ||
        changedParts.trim().isNotEmpty ||
        nextMaintenanceNotes.trim().isNotEmpty ||
        generalStatusNote.trim().isNotEmpty ||
        effectiveProgressNotes.any((note) => note.hasDetails);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'completedDate': completedDate.toIso8601String(),
      'note': note,
      'todaysWork': todaysWork,
      'changedParts': changedParts,
      'nextMaintenanceNotes': nextMaintenanceNotes,
      'generalStatusNote': generalStatusNote,
      'status': status.storageValue,
      'updatedAt': updatedAt.toIso8601String(),
      'plannedMaintenanceDate': plannedMaintenanceDate?.toIso8601String(),
      'progressNotes': progressNotes.map((note) => note.toJson()).toList(),
    };
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    final completedDate = DateTime.parse(json['completedDate'] as String);
    final progressNotesJson = json['progressNotes'];
    final progressNotes = progressNotesJson is List
        ? progressNotesJson
              .map(
                (item) => MaintenanceProgressNote.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
        : <MaintenanceProgressNote>[];

    return MaintenanceRecord(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      completedDate: completedDate,
      note: json['note'] as String?,
      todaysWork: (json['todaysWork'] as String?) ?? '',
      changedParts: (json['changedParts'] as String?) ?? '',
      nextMaintenanceNotes: (json['nextMaintenanceNotes'] as String?) ?? '',
      generalStatusNote: (json['generalStatusNote'] as String?) ?? '',
      status: MaintenanceRecordStatus.fromStorageValue(
        json['status'] as String?,
      ),
      updatedAt: json['updatedAt'] == null
          ? completedDate
          : DateTime.parse(json['updatedAt'] as String),
      plannedMaintenanceDate: json['plannedMaintenanceDate'] == null
          ? null
          : DateTime.parse(json['plannedMaintenanceDate'] as String),
      progressNotes: progressNotes,
    );
  }
}

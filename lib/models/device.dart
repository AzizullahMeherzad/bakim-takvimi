enum MaintenanceCalculationMethod {
  plannedDate,
  completionDate;

  String get storageValue {
    return switch (this) {
      MaintenanceCalculationMethod.plannedDate => 'plannedDate',
      MaintenanceCalculationMethod.completionDate => 'completionDate',
    };
  }

  String get label {
    return switch (this) {
      MaintenanceCalculationMethod.plannedDate => 'Planlanan tarihten itibaren',
      MaintenanceCalculationMethod.completionDate =>
        'Tamamlanma tarihinden itibaren',
    };
  }

  static MaintenanceCalculationMethod fromStorageValue(String? value) {
    return switch (value) {
      'completionDate' => MaintenanceCalculationMethod.completionDate,
      _ => MaintenanceCalculationMethod.plannedDate,
    };
  }
}

class Device {
  static const int twoWeekMaintenanceInterval = 0;

  final String id;
  final String name;
  final String category;
  final String serialNumber;
  final String location;
  final DateTime lastMaintenanceDate;
  final int maintenanceIntervalMonths;
  final MaintenanceCalculationMethod maintenanceCalculationMethod;
  final String? documentPath;

  Device({
    required this.id,
    required this.name,
    required this.category,
    required this.serialNumber,
    required this.location,
    required this.lastMaintenanceDate,
    required this.maintenanceIntervalMonths,
    this.maintenanceCalculationMethod =
        MaintenanceCalculationMethod.plannedDate,
    this.documentPath,
  });

  DateTime get nextMaintenanceDate => calculateNextMaintenanceDate(
    lastMaintenanceDate: lastMaintenanceDate,
    maintenanceIntervalMonths: maintenanceIntervalMonths,
  );

  String get maintenanceIntervalLabel =>
      intervalLabel(maintenanceIntervalMonths);

  String get maintenanceCalculationMethodLabel =>
      maintenanceCalculationMethod.label;

  bool get isOverdue {
    return nextMaintenanceDate.isBefore(DateTime.now());
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final difference = nextMaintenanceDate.difference(now).inDays;
    return difference >= 0 && difference <= 30;
  }

  static DateTime calculateNextMaintenanceDate({
    required DateTime lastMaintenanceDate,
    required int maintenanceIntervalMonths,
  }) {
    if (maintenanceIntervalMonths == twoWeekMaintenanceInterval) {
      return lastMaintenanceDate.add(const Duration(days: 14));
    }

    return DateTime(
      lastMaintenanceDate.year,
      lastMaintenanceDate.month + maintenanceIntervalMonths,
      lastMaintenanceDate.day,
    );
  }

  static String intervalLabel(int intervalMonths) {
    if (intervalMonths == twoWeekMaintenanceInterval) {
      return '2 Hafta';
    }
    return '$intervalMonths Ay';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'serialNumber': serialNumber,
      'location': location,
      'lastMaintenanceDate': lastMaintenanceDate.toIso8601String(),
      'maintenanceIntervalMonths': maintenanceIntervalMonths,
      'maintenanceCalculationMethod': maintenanceCalculationMethod.storageValue,
      'documentPath': documentPath,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      serialNumber: json['serialNumber'],
      location: json['location'],
      lastMaintenanceDate: DateTime.parse(json['lastMaintenanceDate']),
      maintenanceIntervalMonths: json['maintenanceIntervalMonths'],
      maintenanceCalculationMethod:
          MaintenanceCalculationMethod.fromStorageValue(
            json['maintenanceCalculationMethod'] as String?,
          ),
      documentPath: json['documentPath'],
    );
  }
}

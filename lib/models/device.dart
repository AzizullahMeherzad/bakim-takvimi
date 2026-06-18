class Device {
  final String id;
  final String name;
  final String category;
  final String serialNumber;
  final String location;
  final DateTime lastMaintenanceDate;
  final int maintenanceIntervalMonths;

  Device({
    required this.id,
    required this.name,
    required this.category,
    required this.serialNumber,
    required this.location,
    required this.lastMaintenanceDate,
    required this.maintenanceIntervalMonths,
  });

  DateTime get nextMaintenanceDate {
    return DateTime(
      lastMaintenanceDate.year,
      lastMaintenanceDate.month + maintenanceIntervalMonths,
      lastMaintenanceDate.day,
    );
  }

  bool get isOverdue {
    return nextMaintenanceDate.isBefore(DateTime.now());
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final difference = nextMaintenanceDate.difference(now).inDays;
    return difference >= 0 && difference <= 30;
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
    );
  }
}
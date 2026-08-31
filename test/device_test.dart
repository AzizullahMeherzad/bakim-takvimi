import 'package:bakim_takvimi/models/device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Device maintenance interval', () {
    test('keeps existing monthly interval calculation compatible', () {
      final device = Device(
        id: 'monthly-device',
        name: 'Kompresör',
        category: 'Üretim',
        serialNumber: 'K-001',
        location: 'Fabrika',
        lastMaintenanceDate: DateTime(2026, 1, 15),
        maintenanceIntervalMonths: 18,
      );

      expect(device.nextMaintenanceDate, DateTime(2027, 7, 15));
      expect(device.maintenanceIntervalLabel, '18 Ay');
    });

    test('supports a two-week interval without adding a persisted field', () {
      final device = Device(
        id: 'short-device',
        name: 'Pompa',
        category: 'Üretim',
        serialNumber: 'P-001',
        location: 'Fabrika',
        lastMaintenanceDate: DateTime(2026, 7, 1),
        maintenanceIntervalMonths: Device.twoWeekMaintenanceInterval,
      );

      expect(device.nextMaintenanceDate, DateTime(2026, 7, 15));
      expect(device.maintenanceIntervalLabel, '2 Hafta');
      expect(device.toJson()['maintenanceIntervalMonths'], 0);
    });

    test('loads the two-week value from the existing JSON structure', () {
      final device = Device.fromJson({
        'id': 'stored-device',
        'name': 'Jeneratör',
        'category': 'Enerji',
        'serialNumber': 'J-001',
        'location': 'Teknik Alan',
        'lastMaintenanceDate': '2026-07-01T00:00:00.000',
        'maintenanceIntervalMonths': 0,
        'documentPath': null,
      });

      expect(device.nextMaintenanceDate, DateTime(2026, 7, 15));
      expect(device.maintenanceIntervalLabel, '2 Hafta');
    });
  });
}

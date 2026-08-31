import 'package:bakim_takvimi/main.dart';
import 'package:bakim_takvimi/models/device.dart';
import 'package:bakim_takvimi/services/device_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(DeviceService.devices.clear);

  testWidgets('dashboard shows its empty state and zero statistics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));

    expect(find.text('Bakım Takip Paneli'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-total-value')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-upcoming-value')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-overdue-value')), findsOneWidget);
    expect(find.text('Henüz bakım kaydı yok'), findsOneWidget);
    expect(find.text('İlk cihazı ekle'), findsOneWidget);
  });

  testWidgets('dashboard drawer shows the requested navigation items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));

    expect(find.text('Bakım Takip Paneli'), findsOneWidget);
    expect(find.text('Hızlı işlemler'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Cihazlar'), findsOneWidget);
    expect(find.text('Bakım Takvimi'), findsOneWidget);
    expect(find.text('Raporlar'), findsOneWidget);
    expect(find.text('Bildirimler'), findsOneWidget);
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Çıkış Yap'), findsOneWidget);
  });

  testWidgets('dashboard reflects stored devices and maintenance priority', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    DeviceService.devices.addAll([
      Device(
        id: 'overdue-device',
        name: 'Geciken Kompresör',
        category: 'Kompresör',
        serialNumber: 'K-001',
        location: 'Üretim Alanı',
        lastMaintenanceDate: DateTime(now.year - 1, now.month, now.day),
        maintenanceIntervalMonths: 1,
      ),
      Device(
        id: 'normal-device',
        name: 'Yeni Jeneratör',
        category: 'Jeneratör',
        serialNumber: 'J-001',
        location: 'Teknik Alan',
        lastMaintenanceDate: now,
        maintenanceIntervalMonths: 12,
      ),
    ]);

    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('dashboard-total-value'))).data,
      '2',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('dashboard-overdue-value')))
          .data,
      '1',
    );
    expect(find.text('Geciken Kompresör'), findsOneWidget);
    expect(find.text('Tümünü gör'), findsOneWidget);
  });
}

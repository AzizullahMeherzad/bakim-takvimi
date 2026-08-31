import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/device.dart';
import 'notification_service.dart';

class DeviceService {
  static final List<Device> devices = [];

  // Cihazları telefona/bilgisayara kaydet
  static Future<void> saveDevices() async {
    final prefs = await SharedPreferences.getInstance();

    final deviceList = devices.map((device) => device.toJson()).toList();

    await prefs.setString('devices', jsonEncode(deviceList));

    await NotificationService.syncMaintenanceNotifications(devices);
  }

  // Uygulama açılınca kayıtlı cihazları yükle
  static Future<void> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString('devices');

    if (jsonString == null) return;

    final List decoded = jsonDecode(jsonString);

    devices.clear();

    devices.addAll(decoded.map((item) => Device.fromJson(item)));
  }

  // Cihaz ekle
  static Future<void> addDevice(Device device) async {
    devices.add(device);
    await saveDevices();
  }

  // Cihaz sil
  static Future<void> deleteDevice(String id) async {
    devices.removeWhere((device) => device.id == id);

    await saveDevices();
  }

  // Cihaz güncelle
  static Future<void> updateDevice(Device updatedDevice) async {
    final index = devices.indexWhere((device) => device.id == updatedDevice.id);

    if (index != -1) {
      devices[index] = updatedDevice;
      await saveDevices();
    }
  }

  // Tüm cihazları getir
  static List<Device> getDevices() {
    return devices;
  }

  // Dashboard istatistikleri
  static int get totalDevices => devices.length;

  static int get upcomingCount =>
      devices.where((device) => device.isUpcoming).length;

  static int get overdueCount =>
      devices.where((device) => device.isOverdue).length;
}

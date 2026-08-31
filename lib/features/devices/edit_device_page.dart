import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../services/device_service.dart';
import 'widgets/device_form.dart';

class EditDevicePage extends StatefulWidget {
  const EditDevicePage({super.key, required this.device});

  final Device device;

  @override
  State<EditDevicePage> createState() => _EditDevicePageState();
}

class _EditDevicePageState extends State<EditDevicePage> {
  Future<void> _updateDevice(DeviceFormData data) async {
    final updatedDevice = Device(
      id: widget.device.id,
      name: data.name,
      category: data.category,
      serialNumber: data.serialNumber,
      location: data.location,
      lastMaintenanceDate: data.lastMaintenanceDate,
      maintenanceIntervalMonths: data.maintenanceIntervalMonths,
      maintenanceCalculationMethod: data.maintenanceCalculationMethod,
      documentPath: widget.device.documentPath,
    );

    await DeviceService.updateDevice(updatedDevice);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cihaz başarıyla güncellendi')),
    );
    Navigator.of(context).pop(updatedDevice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cihazı düzenle')),
      body: DeviceForm(
        initialDevice: widget.device,
        submitLabel: 'Değişiklikleri kaydet',
        submitIcon: Icons.save_outlined,
        onSubmit: _updateDevice,
      ),
    );
  }
}

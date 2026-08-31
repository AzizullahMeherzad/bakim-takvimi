import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../services/device_service.dart';
import 'widgets/device_form.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  Future<void> _saveDevice(DeviceFormData data) async {
    final device = Device(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: data.name,
      category: data.category,
      serialNumber: data.serialNumber,
      location: data.location,
      lastMaintenanceDate: data.lastMaintenanceDate,
      maintenanceIntervalMonths: data.maintenanceIntervalMonths,
      maintenanceCalculationMethod: data.maintenanceCalculationMethod,
    );

    await DeviceService.addDevice(device);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cihaz başarıyla eklendi')));
    Navigator.of(context).pop(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni cihaz')),
      body: DeviceForm(
        submitLabel: 'Cihazı kaydet',
        submitIcon: Icons.add_circle_outline_rounded,
        onSubmit: _saveDevice,
      ),
    );
  }
}

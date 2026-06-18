import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';

class EditDevicePage extends StatefulWidget {
  final Device device;

  const EditDevicePage({
    super.key,
    required this.device,
  });

  @override
  State<EditDevicePage> createState() => _EditDevicePageState();
}

class _EditDevicePageState extends State<EditDevicePage> {
  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController serialController;
  late TextEditingController locationController;

  late int intervalMonths;
  late DateTime lastMaintenanceDate;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.device.name);
    categoryController = TextEditingController(text: widget.device.category);
    serialController = TextEditingController(text: widget.device.serialNumber);
    locationController = TextEditingController(text: widget.device.location);

    intervalMonths = widget.device.maintenanceIntervalMonths;
    lastMaintenanceDate = widget.device.lastMaintenanceDate;
  }

  DateTime get nextMaintenanceDate {
    return DateTime(
      lastMaintenanceDate.year,
      lastMaintenanceDate.month + intervalMonths,
      lastMaintenanceDate.day,
    );
  }

  String formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }

  Future<void> selectLastMaintenanceDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: lastMaintenanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        lastMaintenanceDate = pickedDate;
      });
    }
  }

  Future<void> updateDevice() async {
    final updatedDevice = Device(
      id: widget.device.id,
      name: nameController.text,
      category: categoryController.text,
      serialNumber: serialController.text,
      location: locationController.text,
      lastMaintenanceDate: lastMaintenanceDate,
      maintenanceIntervalMonths: intervalMonths,
    );

    await DeviceService.updateDevice(updatedDevice);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cihaz güncellendi")),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cihaz Düzenle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Cihaz Adı"),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Kategori"),
            ),
            TextField(
              controller: serialController,
              decoration: const InputDecoration(labelText: "Seri No"),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Konum"),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Son Bakım Tarihi"),
              subtitle: Text(formatDate(lastMaintenanceDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: selectLastMaintenanceDate,
            ),
            DropdownButtonFormField<int>(
              value: intervalMonths,
              decoration: const InputDecoration(labelText: "Bakım Periyodu"),
              items: const [
                DropdownMenuItem(value: 1, child: Text("1 Ay")),
                DropdownMenuItem(value: 3, child: Text("3 Ay")),
                DropdownMenuItem(value: 6, child: Text("6 Ay")),
                DropdownMenuItem(value: 12, child: Text("12 Ay")),
              ],
              onChanged: (value) {
                setState(() {
                  intervalMonths = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text("Yeni Sonraki Bakım Tarihi"),
                subtitle: Text(formatDate(nextMaintenanceDate)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: updateDevice,
              icon: const Icon(Icons.save),
              label: const Text("Güncelle"),
            ),
          ],
        ),
      ),
    );
  }
}
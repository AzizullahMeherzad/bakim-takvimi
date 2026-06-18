import 'package:flutter/material.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';
import 'edit_device_page.dart';

class DeviceDetailPage extends StatelessWidget {
  final Device device;

  const DeviceDetailPage({
    super.key,
    required this.device,
  });

  String formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }

  String getStatusText() {
    if (device.isOverdue) return "Gecikmiş";
    if (device.isUpcoming) return "Yaklaşıyor";
    return "Normal";
  }

  Future<void> deleteDevice(BuildContext context) async {
    await DeviceService.deleteDevice(device.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cihaz silindi")),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(title: const Text("Cihaz Adı"), subtitle: Text(device.name)),
                  ListTile(title: const Text("Kategori"), subtitle: Text(device.category)),
                  ListTile(title: const Text("Seri No"), subtitle: Text(device.serialNumber)),
                  ListTile(title: const Text("Konum"), subtitle: Text(device.location)),
                  ListTile(title: const Text("Son Bakım Tarihi"), subtitle: Text(formatDate(device.lastMaintenanceDate))),
                  ListTile(title: const Text("Sonraki Bakım Tarihi"), subtitle: Text(formatDate(device.nextMaintenanceDate))),
                  ListTile(title: const Text("Durum"), subtitle: Text(getStatusText())),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDevicePage(device: device),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text("Düzenle"),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => deleteDevice(context),
              icon: const Icon(Icons.delete),
              label: const Text("Cihazı Sil"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
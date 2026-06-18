import 'package:flutter/material.dart';
import 'features/devices/add_device_page.dart';
import 'features/devices/device_list_page.dart';


void main() {
  runApp(const BakimTakvimiApp());
}

class BakimTakvimiApp extends StatelessWidget {
  const BakimTakvimiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bakım Takvimi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Widget infoCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bakım Takvimi"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoCard(
              "Toplam Cihaz",
              "25",
              Icons.devices,
              Colors.blue,
            ),
            infoCard(
              "Yaklaşan Bakım",
              "4",
              Icons.schedule,
              Colors.orange,
            ),
            infoCard(
              "Geciken Bakım",
              "2",
              Icons.warning,
              Colors.red,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddDevicePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Cihaz Ekle"),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeviceListPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text("Cihazları Gör"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
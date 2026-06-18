import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'features/devices/add_device_page.dart';
import 'features/devices/device_list_page.dart';
import 'services/device_service.dart';
import 'services/notification_service.dart';
import 'features/maintenance/maintenance_calendar_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceService.loadDevices();
  await NotificationService.initialize();

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<void> openAddDevicePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDevicePage()),
    );
    setState(() {});
  }

  Future<void> openDeviceListPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeviceListPage()),
    );
    setState(() {});
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget actionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }

  Widget statusChart() {
    final total = DeviceService.totalDevices;
    final upcoming = DeviceService.upcomingCount;
    final overdue = DeviceService.overdueCount;
    final normal = total - upcoming - overdue;

    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("Grafik için henüz cihaz eklenmedi"),
        ),
      );
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Bakım Durumu Dağılımı",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: normal.toDouble(),
                      title: "Normal\n$normal",
                      radius: 60,
                      color: Colors.green,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: upcoming.toDouble(),
                      title: "Yaklaşan\n$upcoming",
                      radius: 60,
                      color: Colors.orange,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: overdue.toDouble(),
                      title: "Geciken\n$overdue",
                      radius: 60,
                      color: Colors.red,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = DeviceService.totalDevices.toString();
    final upcoming = DeviceService.upcomingCount.toString();
    final overdue = DeviceService.overdueCount.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bakım Takvimi"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bakım Takip Paneli",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Cihazlarınızı, bakım tarihlerinizi ve geciken işlemleri tek yerden takip edin.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                statCard(
                  title: "Toplam",
                  value: total,
                  icon: Icons.devices,
                  color: Colors.indigo,
                ),
                statCard(
                  title: "Yaklaşan",
                  value: upcoming,
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
                statCard(
                  title: "Geciken",
                  value: overdue,
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            statusChart(),

            const SizedBox(height: 24),

            actionButton(
              text: "Yeni Cihaz Ekle",
              icon: Icons.add,
              onPressed: openAddDevicePage,
            ),

            const SizedBox(height: 12),

            actionButton(
              text: "Cihazları Görüntüle",
              icon: Icons.list,
              onPressed: openDeviceListPage,
            ),

            const SizedBox(height: 12),

            actionButton(
              text: "Bakım Takvimini Gör",
              icon: Icons.calendar_month,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaintenanceCalendarPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            actionButton(
              text: "Test Bildirimi Gönder",
              icon: Icons.notifications,
              onPressed: () {
                NotificationService.showInstantNotification(
                  title: "Bakım Uyarısı",
                  body: "Jeneratör bakım süresi yaklaşıyor.",
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
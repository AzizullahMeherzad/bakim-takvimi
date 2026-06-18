import 'package:flutter/material.dart';
import '../../services/device_service.dart';
import '../devices/device_detail_page.dart';

class MaintenanceCalendarPage extends StatefulWidget {
  const MaintenanceCalendarPage({super.key});

  @override
  State<MaintenanceCalendarPage> createState() =>
      _MaintenanceCalendarPageState();
}

class _MaintenanceCalendarPageState extends State<MaintenanceCalendarPage> {
  String searchText = "";
  String selectedFilter = "Tümü";

  String formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }

  Widget filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedFilter == label,
        onSelected: (_) {
          setState(() {
            selectedFilter = label;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = DeviceService.getDevices();

    final filteredDevices = devices.where((device) {
      final query = searchText.toLowerCase();

      final matchesSearch =
          device.name.toLowerCase().contains(query) ||
          device.category.toLowerCase().contains(query) ||
          device.location.toLowerCase().contains(query) ||
          device.serialNumber.toLowerCase().contains(query);

      bool matchesFilter = true;

      switch (selectedFilter) {
        case "Geciken":
          matchesFilter = device.isOverdue;
          break;
        case "Yaklaşan":
          matchesFilter = device.isUpcoming;
          break;
        case "30 Gün":
          final today = DateTime.now();
          final todayOnly = DateTime(today.year, today.month, today.day);
          final maintenanceDate = DateTime(
            device.nextMaintenanceDate.year,
            device.nextMaintenanceDate.month,
            device.nextMaintenanceDate.day,
          );

          final diff = maintenanceDate.difference(todayOnly).inDays;
          matchesFilter = diff >= 0 && diff <= 30;
          break;
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    filteredDevices.sort(
      (a, b) => a.nextMaintenanceDate.compareTo(b.nextMaintenanceDate),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bakım Takvimi"),
      ),
      body: devices.isEmpty
          ? const Center(child: Text("Henüz bakım kaydı yok"))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Bakım kaydı ara",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        filterChip("Tümü"),
                        filterChip("Yaklaşan"),
                        filterChip("Geciken"),
                        filterChip("30 Gün"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: filteredDevices.isEmpty
                      ? const Center(child: Text("Sonuç bulunamadı"))
                      : ListView.builder(
                          itemCount: filteredDevices.length,
                          itemBuilder: (context, index) {
                            final device = filteredDevices[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: Icon(
                                  device.isOverdue
                                      ? Icons.warning
                                      : device.isUpcoming
                                          ? Icons.schedule
                                          : Icons.event_available,
                                ),
                                title: Text(device.name),
                                subtitle: Text(
                                  "${device.category} • ${device.location}",
                                ),
                                trailing: Text(
                                  formatDate(device.nextMaintenanceDate),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: device.isOverdue
                                        ? Colors.red
                                        : device.isUpcoming
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DeviceDetailPage(device: device),
                                    ),
                                  );

                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
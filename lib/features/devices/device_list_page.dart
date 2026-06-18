import 'package:flutter/material.dart';
import '../../services/device_service.dart';
import 'device_detail_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
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

  String statusText(device) {
    if (device.isOverdue) return "Gecikmiş";
    if (device.isUpcoming) return "Yaklaşıyor";
    return "Normal";
  }

  @override
  Widget build(BuildContext context) {
    final allDevices = DeviceService.getDevices();

    final filteredDevices = allDevices.where((device) {
      final query = searchText.toLowerCase();

      final matchesSearch =
          device.name.toLowerCase().contains(query) ||
          device.category.toLowerCase().contains(query) ||
          device.location.toLowerCase().contains(query) ||
          device.serialNumber.toLowerCase().contains(query);

      bool matchesFilter = true;

      switch (selectedFilter) {
        case "Normal":
          matchesFilter = !device.isOverdue && !device.isUpcoming;
          break;
        case "Yaklaşan":
          matchesFilter = device.isUpcoming;
          break;
        case "Geciken":
          matchesFilter = device.isOverdue;
          break;
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cihazlar"),
      ),
      body: allDevices.isEmpty
          ? const Center(
              child: Text(
                "Henüz cihaz eklenmedi",
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Cihaz ara",
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
                        filterChip("Normal"),
                        filterChip("Yaklaşan"),
                        filterChip("Geciken"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: filteredDevices.isEmpty
                      ? const Center(
                          child: Text("Sonuç bulunamadı"),
                        )
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
                                          : Icons.devices,
                                ),
                                title: Text(device.name),
                                subtitle: Text(
                                  "${device.category} • ${device.location}\nSonraki bakım: ${formatDate(device.nextMaintenanceDate)}",
                                ),
                                isThreeLine: true,
                                trailing: Text(statusText(device)),
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
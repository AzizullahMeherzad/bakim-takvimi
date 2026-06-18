import 'package:flutter/material.dart';

class DeviceListPage extends StatelessWidget {
  const DeviceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cihazlar"),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.devices),
            title: Text("Yangın Tüpü A-12"),
            subtitle: Text("Depo Katı"),
          ),
          ListTile(
            leading: Icon(Icons.devices),
            title: Text("Jeneratör"),
            subtitle: Text("Makine Dairesi"),
          ),
        ],
      ),
    );
  }
}
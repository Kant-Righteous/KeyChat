import 'package:flutter/material.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';

class ProvidersPage extends StatelessWidget {
  const ProvidersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Providers'),
      ),
      body: ListView.builder(
        itemCount: providerPresets.length,
        itemBuilder: (context, index) {
          final preset = providerPresets[index];
          return ListTile(
            leading: Icon(
              preset.isCustom ? Icons.add_circle_outline : Icons.cloud_outlined,
            ),
            title: Text(preset.name),
            subtitle: Text(preset.description),
            trailing: const Text(
              'Not configured',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProviderConfigPage(preset: preset),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

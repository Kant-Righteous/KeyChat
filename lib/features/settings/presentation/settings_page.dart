import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.palette),
            title: Text('Appearance'),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacy'),
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About KeyChat'),
          ),
        ],
      ),
    );
  }
}

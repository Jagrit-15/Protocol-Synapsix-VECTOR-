import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _titleTaps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            setState(() => _titleTaps += 1);
            if (_titleTaps >= 7) {
              _titleTaps = 0;
              Navigator.of(context).pushNamed('/debug');
            }
          },
          child: const Text('Settings'),
        ),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('Use OSM tiles (default)'),
            subtitle: Text('Mapbox token is optional and commented in .env.example'),
            trailing: Icon(Icons.check),
          ),
          ListTile(
            title: Text('Background sensing'),
            subtitle: Text('PLACEHOLDER flutter_background_service — not started'),
          ),
          ListTile(
            title: Text('Hidden debug'),
            subtitle: Text('Tap the Settings title seven times'),
          ),
        ],
      ),
    );
  }
}

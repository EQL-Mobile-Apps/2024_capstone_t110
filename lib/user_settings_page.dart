import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsPage extends StatefulWidget {
  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  double _notificationVolume = 50.0;
  double _mapZoomLevel = 50.0;
  double _reportingFrequency = 50.0;
  bool _darkMode = false;
  bool _locationServices = false;
  bool _emailNotifications = false;
  List<String> _reportedOutages = [];

  @override
  void initState() {
    super.initState();
    _loadReportedOutages();
    _loadSettings();
  }

  Future<void> _loadReportedOutages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _reportedOutages = prefs.getStringList('reportedOutages') ?? [];
    });
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _locationServices = prefs.getBool('locationServices') ?? false;
      _emailNotifications = prefs.getBool('emailNotifications') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('locationServices', _locationServices);
    await prefs.setBool('emailNotifications', _emailNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Volume',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _notificationVolume,
              min: 0,
              max: 100,
              divisions: 100,
              label: _notificationVolume.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _notificationVolume = value;
                });
              },
            ),
            Text(
              'Map Zoom Level',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _mapZoomLevel,
              min: 0,
              max: 100,
              divisions: 100,
              label: _mapZoomLevel.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _mapZoomLevel = value;
                });
              },
            ),
            Text(
              'Reporting Frequency',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _reportingFrequency,
              min: 0,
              max: 100,
              divisions: 100,
              label: _reportingFrequency.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _reportingFrequency = value;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              'Preferences',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: Text('Dark Mode'),
              value: _darkMode,
              onChanged: (bool value) {
                setState(() {
                  _darkMode = value;
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: Text('Location Services'),
              value: _locationServices,
              onChanged: (bool value) {
                setState(() {
                  _locationServices = value;
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: Text('Email Notifications'),
              value: _emailNotifications,
              onChanged: (bool value) {
                setState(() {
                  _emailNotifications = value;
                });
                _saveSettings();
              },
            ),
            SizedBox(height: 20),
            Text(
              'Reported Outages',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _reportedOutages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_reportedOutages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

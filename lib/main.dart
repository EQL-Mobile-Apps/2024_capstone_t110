import 'package:flutter/material.dart';
import 'home_page.dart';
import 'user_settings_page.dart';
import 'info_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      routes: {
        '/settings': (context) => UserSettingsPage(),
        '/info': (context) => InfoPage(),
      },
    );
  }
}

import 'package:flutter/material.dart';

class SettingsDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer( // Newly added drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: const <Widget>[
            ListTile(
              leading: Icon(Icons.account_circle_rounded),
              title: Text("Log in"),
            ),
            ListTile(
              leading: Icon(Icons.account_circle_rounded),
              title: Text("Log out"),
            ),
            ListTile(
              leading: Icon(Icons.import_export),
              title: Text("Export Documents"),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
            ),
          ]
        ),
      );
  }
}
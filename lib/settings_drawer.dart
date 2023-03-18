import 'package:flutter/material.dart';

class SettingsDrawer extends StatelessWidget {

  VoidCallback? modifyCurrentWeekRange;
  int? currentWeekRange;

  SettingsDrawer(this.modifyCurrentWeekRange, this.currentWeekRange);

  @override
  Widget build(BuildContext context) {
    ButtonStyle style = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));

    return Drawer( // Newly added drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  style: style,
                  onPressed: modifyCurrentWeekRange,
                  child: Text("Alternate time range"),
                ),
                Text(currentWeekRange.toString() + " weeks"),
              ],
            )

          ]
        ),
      );
  }
}
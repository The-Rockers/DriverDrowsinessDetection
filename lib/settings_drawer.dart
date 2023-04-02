import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SettingsDrawer extends StatelessWidget {

  VoidCallback? modifyCurrentWeekRange;
  int? currentWeekRange;

  VoidCallback? alternateChartType;
  bool isBarChart;

  final void Function(String?)? Function() selectFileType;
  VoidCallback? exportFile;
  List<String> fileList;
  String fileType;

  void Function() Function() selectSignInWithGoogle;

  SettingsDrawer({this.modifyCurrentWeekRange, this.alternateChartType, required this.selectSignInWithGoogle, required this.exportFile, required this.selectFileType, required this.fileList, required this.fileType, required this.isBarChart, this.currentWeekRange});

  @override
  Widget build(BuildContext context) {
    ButtonStyle style = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
    String currentChartType = "";

    if(isBarChart){ // replace with ternary expression
      currentChartType = "Bar Chart";
    }
    else{
      currentChartType = "Line Chart";
    }

    return Drawer( // Newly added drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.account_circle_rounded),
              title: Text("Log in"),
              onTap: (){
                selectSignInWithGoogle()();
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle_rounded),
              title: Text("Log out"),
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
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  style: style,
                  onPressed: alternateChartType,
                  child: Text("Alternate chart type"),
                ),
                Text(currentChartType),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  style: style,
                  onPressed: exportFile,
                  child: Text("Export As File"),
                ),
                DropdownButton<String>(
                  value: fileType, // fileType needs defualt value to avoid crashing
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style: const TextStyle(color: Colors.blue),
                  underline: Container(
                    height: 2,
                    color: Colors.blue,
                  ),
                  onChanged: selectFileType(),
                  items: fileList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ]
        ),
      );
  }
}

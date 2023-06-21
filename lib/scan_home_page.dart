import 'package:flutter/material.dart';

class ScanHomePage extends StatelessWidget{

  void Function() Function() scan;
  String connectionStatusText;

  ScanHomePage({required this.scan, required this.connectionStatusText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [

          ElevatedButton(
            style: null,
            onPressed: scan(),
            child: Text("Search for Pi devices"),
          ),
          Text(connectionStatusText),
        ],
      ),
    );
  }

}
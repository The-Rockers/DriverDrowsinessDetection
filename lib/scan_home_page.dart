import 'package:flutter/material.dart';

class ScanHomePage extends StatelessWidget{

  void Function() Function() scan;
  String connectionStatusText;

  ScanHomePage({required this.scan, required this.connectionStatusText});

  @override
  Widget build(BuildContext context) {
    return 
      Scaffold(
        body:Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text("ADDDS Bluetooth App"),
            const SizedBox(height: 50),
              Image.asset(
                "assets/images/logo.png",
                height:200,
                scale: 2,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                style: null,
                onPressed: scan(),
                child: Text("Search for Pi devices"),
              ),
              Text(connectionStatusText),
            ],
          ),
        )
      );
  }

}
import 'package:flutter/material.dart';
//import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp>{

  //final flutterReactiveBle = FlutterReactiveBle();
  String text = "test";

  void _handleTap() {
    setState(() {
      text += "a";
    });
  }

  /*
  void scan(){
    flutterReactiveBle.scanForDevices(withServices: [], /*scanMode: ScanMode.lowLatency*/).listen((device) {
      print("Scanning for devices");
    }, onError: () {
      print("Error in scanning for devices");
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ADDDS Bluetooth App",
      home:Scaffold(
        //body: Center(child: Text("Test")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: _handleTap,
                child: Text("Tap me"),
              ),
              Text(text),
            ],
          ),
       )
      )
    );
  }

}
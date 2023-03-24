// https://www.ubiqueiot.com/posts/flutter-reactive-ble
// Tutorial Reference

import 'dart:async';
import 'dart:io' show Platform;

import 'package:location_permissions/location_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp>{

  // Some state management stuff
  bool _foundDeviceWaitingToConnect = false;
  bool _scanStarted = false;
  bool _connected = false;
// Bluetooth related variables
  late DiscoveredDevice _ubiqueDevice;
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late QualifiedCharacteristic _rxCharacteristic;
// These are the UUIDs of your device
  final Uuid serviceUuid = Uuid.parse("75C276C3-8F97-20BC-A143-B354244886D4");
  final Uuid characteristicUuid = Uuid.parse("6ACF4F08-CC9D-D495-6B41-AA7E60C4E8A6");
  
  String text = " ";

  void _startScan() async {
// Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });
    PermissionStatus permission;
    if (Platform.isAndroid) {
      
      // For some reason, bluetooth scanning won't work unless location
      // is on and paermissions are granted. No idea why.

      permission = await LocationPermissions().requestPermissions();
      if (permission == PermissionStatus.granted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }
// Main scanning logic happens here ⤵️
    if (permGranted) {
      _scanStream = flutterReactiveBle
          .scanForDevices(withServices: []).listen((device) {

            print("------------ Scanning for devices ------------------");
            print("Device: " + device.name);

            if(device.name != ""){
              setState(){
                text += device.name;
              }
            }
      });
    }
  }

  void _handleTap() {
    setState(() {
      text += "a";
    });
  }

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
                onPressed: _startScan,
                child: Text("Start Scan"),
              ),
              Text(text),
            ],
          ),
       )
      )
    );
  }

}
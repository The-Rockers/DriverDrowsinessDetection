// https://www.ubiqueiot.com/posts/flutter-reactive-ble
// Tutorial Reference

/*

I/flutter (18362): Device: nuraphone 926
I/flutter (18362): Device ID: 74:1A:E0:21:17:C0
I/flutter (18362): Device UUIDs: 0000180f-0000-1000-8000-00805f9b34fb

*/

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
  late DiscoveredDevice _bluetoothDevice;
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late QualifiedCharacteristic _rxCharacteristic;
// These are the UUIDs of your device
  //final Uuid serviceUuid = Uuid.parse("75C276C3-8F97-20BC-A143-B354244886D4"); // Sample Uuid
  final Uuid serviceUuid = Uuid.parse("0000180f-0000-1000-8000-00805f9b34fb"); // Uuid of my nuraphone
  final Uuid characteristicUuid = Uuid.parse("6ACF4F08-CC9D-D495-6B41-AA7E60C4E8A6");
  
  String text = "No devices discovered yet";
  String text1 = "No device connected yet";

 // State bluetooth scan for avaialble devices. Bluetooth + location needs to be on
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

            // change device name to device that will be seen on the Pi
            if(device.name == "nuraphone 926"){
              _bluetoothDevice = device;
              _foundDeviceWaitingToConnect = true;

              print("Device: " + device.name);
              print("Device ID: " + device.id);
              for(var id in device.serviceUuids){
                print("Device UUIDs: " + id.toString());
              }

              setState(() {
                text = "Nuraphone Found";
              });
            }
      });
    }
  }

  void _connectToDevice() {
    // We're done scanning, we can cancel it
    _scanStream.cancel();
    // Let's listen to our connection so we can make updates on a state change
    Stream<ConnectionStateUpdate> _currentConnectionStream = flutterReactiveBle
        .connectToAdvertisingDevice(
            id: _bluetoothDevice.id,
            prescanDuration: const Duration(seconds: 5),
            withServices: [serviceUuid],
          );
    _currentConnectionStream.listen((event) {
      switch (event.connectionState) {
        // We're connected and good to go!
        case DeviceConnectionState.connected:
          {
            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: serviceUuid,
                characteristicId: characteristicUuid, // placeholder. This value is not requried I think
                deviceId: event.deviceId);
            setState(() {
              text1 = "Connected to nuraphone";
              _foundDeviceWaitingToConnect = false;
              _connected = true;
            });
            break;
          }
        // Can add various state state updates on disconnect
        case DeviceConnectionState.disconnected:
          {
            setState(() {
              text1 = "Not connected to nuraphone";
            });
            break;
          }
        default:
      }
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
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: _connectToDevice,
                child: Text("Connect to nuraphone"),
              ),
              Text(text1),
            ],
          ),
       )
      )
    );
  }

}
// https://www.ubiqueiot.com/posts/flutter-reactive-ble
// Tutorial Reference

/*

I/flutter (18362): Device: nuraphone 926
I/flutter (18362): Device ID: 74:1A:E0:21:17:C0
I/flutter (18362): Device UUIDs: 0000180f-0000-1000-8000-00805f9b34fb

*/

/*

A certain number of characteristic UUIDs as provided by:
https://asteroidos.org/wiki/ble-profiles/#:~:text=many%20other%20devices.-,Battery%20Service%20(UUID%3A%200000180F%2D0000,%2D1000%2D8000%2D00805f9b34fb)&text=This%20characteristic%20can%20be%20read,representing%20the%20current%20battery%20level.

Volume: 00007006-0000-0000-0000-00A57E401D05
battery level: 00002a19-0000-1000-8000-00805f9b34fb

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
  late QualifiedCharacteristic _rxCharacteristic1;

  final Uuid serviceUuid = Uuid.parse("0000180f-0000-1000-8000-00805f9b34fb"); // Uuid of my nuraphone. Change for pi
  final Uuid characteristicUuid = Uuid.parse("00002a19-0000-1000-8000-00805f9b34fb"); // Battery level characteristic UUID
  
  String text = "No devices discovered yet";
  String text1 = "No device connected yet";
  String text2 = "No command sent yet";

  //Start bluetooth scan for avaialble devices. Bluetooth + location needs to be on for android
  void _startScan() async { // Works
    // Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });
    PermissionStatus permission;
    if (Platform.isAndroid) {
      
      /*
      For some reason, bluetooth scanning won't work unless location
      is on and paermissions are granted. No idea why.
      */

      permission = await LocationPermissions().requestPermissions();
      if (permission == PermissionStatus.granted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }
    // Main scanning logic happens here ⤵️
    if (permGranted) {
      _scanStream = flutterReactiveBle
          .scanForDevices(withServices: []).listen((device) { // Scan for all devices

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
          }); // Had to remove the onErrorBlock (threw an exception at runtime)
    }
  }

  void _connectToDevice() {
    // We're done scanning, we can cancel it
    _scanStream.cancel();
    // Let's listen to our connection so we can make updates on a state change
    Stream<ConnectionStateUpdate> _currentConnectionStream = flutterReactiveBle
        .connectToAdvertisingDevice( // connectToAdvertisingDevice is for resolving Android problems
            id: _bluetoothDevice.id,
            prescanDuration: const Duration(seconds: 5),
            withServices: [serviceUuid], // hardcoded to nuraphone
          );
    _currentConnectionStream.listen((event) {
      switch (event.connectionState) {
        // We're connected and good to go!
        case DeviceConnectionState.connected:
          {
            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: serviceUuid,
                characteristicId: characteristicUuid, // Battery level
                deviceId: event.deviceId);
            setState(() {
              text1 = "Connected to Device";
              _foundDeviceWaitingToConnect = false;
              _connected = true;
            });
            break;
          }
        // Can add various state state updates on disconnect
        case DeviceConnectionState.disconnected:
          {
            setState(() {
              text1 = "Not connected to Device";
            });
            break;
          }
        default:
      }
    });
  }

  void _testRead() async{
    final response = await flutterReactiveBle.readCharacteristic(_rxCharacteristic);

    for(var i = 0; i < response.length; i++){
      print("Battery level:" + response[i].toString());
    }

    setState((){
      text2 = "Read command sent";
    });
  }
  

  void _testWrite(){
    if (_connected) {

      flutterReactiveBle
      .writeCharacteristicWithResponse(_rxCharacteristic, value: [
        123,
      ]);

      setState(() {
        text2 = "Command sent";
      });

    }
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
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: _testRead,
                child: Text("Read Characteristic"),
              ),
              Text(text2),
            ],
          ),
       )
      )
    );
  }

}
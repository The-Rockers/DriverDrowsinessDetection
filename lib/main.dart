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

import 'package:flutter/material.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:location_permissions/location_permissions.dart' as LocationPermissions;
import 'package:permission_handler/permission_handler.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

import 'google_clientId.dart';

import 'dart:async';
import 'dart:io' show Platform;

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
  bool isSubscribed = false;

  final Uuid serviceUuid = Uuid.parse("6e400001-b5a3-f393-e0a9-e50e24dcca9e"); // UUID for PI Gatt service
  final Uuid characteristicUuid = Uuid.parse("6e400002-b5a3-f393-e0a9-e50e24dcca9e"); // RX characterstic (works!) 
  final Uuid characteristicUuid1 = Uuid.parse("6e400003-b5a3-f393-e0a9-e50e24dcca9e"); // TX characterstic 
  final String RPIName = "rpi-gatt-server";
  // RPI device ID DC:A6:32:82:5A:50

  // final Uuid serviceUuid = Uuid.parse("0000180f-0000-1000-8000-00805f9b34fb"); // Uuid of my battery service on my nuraphone. Change for pi
  // final Uuid characteristicUuid = Uuid.parse("00002a19-0000-1000-8000-00805f9b34fb"); // Battery level characteristic UUID

  String text = "No devices discovered yet";
  String text1 = "No device connected yet";
  String text2 = "No command sent yet";
  String userIdText = "no user id yet";

  late UserCredential globalUser;
  late String JWT;

  @override
  void initState() {
    initializeFirebaseApp();
  }

  void initializeFirebaseApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  //Start bluetooth scan for avaialble devices. Bluetooth + location needs to be on for android
  void _startScan() async { // Works
    // Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });

    LocationPermissions.PermissionStatus locationPermission;
    PermissionStatus bluetoothScanPermission;
    PermissionStatus bluetoothAdvertisePermission;
    PermissionStatus bluetoothConnectPermission;

    if (Platform.isAndroid) {
      
      /*
      For some reason, bluetooth scanning won't work unless location
      is on and paermissions are granted. No idea why.
      */

      bluetoothConnectPermission = await Permission.bluetoothConnect.request();
      bluetoothAdvertisePermission = await Permission.bluetoothAdvertise.request();
      bluetoothScanPermission = await Permission.bluetoothScan.request();
      locationPermission = await LocationPermissions.LocationPermissions().requestPermissions();

      if (locationPermission == LocationPermissions.PermissionStatus.granted) permGranted = true;

      //permGranted = true;

    } else if (Platform.isIOS) {
      permGranted = true;
    }
    // Main scanning logic happens here ⤵️
    if (permGranted) {
      _scanStream = flutterReactiveBle
          .scanForDevices(withServices: []).listen((device) { // Scan for all devices

            //print("------------ Scanning for devices ------------------");
            // change this TODO
            // change device name to device that will be seen on the Pi
            if(device.name == "rpi-gatt-server"){ // If the device is the PI
              _bluetoothDevice = device;
              _foundDeviceWaitingToConnect = true;

              print("Device: " + device.name);
              print("Device ID: " + device.id);

              for(var id in device.serviceUuids){
                print("Service UUIDs: " + id.toString());
              }

              setState(() {
                text = "RPI service Found!";
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
            withServices: [serviceUuid, characteristicUuid], // hardcoded to RPI
          );
    _currentConnectionStream.listen((event) {
      switch (event.connectionState) {
        // We're connected and good to go!
        case DeviceConnectionState.connected:
          {
            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: serviceUuid, // RPI gatt service
                characteristicId: characteristicUuid, // 
                deviceId: event.deviceId);
            _rxCharacteristic1 = QualifiedCharacteristic(
                serviceId: serviceUuid, // RPI gatt service
                characteristicId: characteristicUuid1, // 
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
        default: // none
      }
    });
  }

  void _testRead() async{ // dont need right now

    // flutterReactiveBle.subscribeToCharacteristic(_rxCharacteristic).listen((data) {
    //   print("Info changed ----0---- :" + data.toString());
    // }, onError: (dynamic error) {
    //   print("Reading error -------------: ");
    // });

    if(!isSubscribed){

      flutterReactiveBle.subscribeToCharacteristic(_rxCharacteristic1).listen((data) {

        String response = '';

        data.forEach((value) => {response += String.fromCharCode(value)});
        print("Info changed (interpreted) : " + response);

      }, onError: (dynamic error) {
        print("Reading error");
      });

      isSubscribed = true;

    }

    setState((){
      text2 = "Subscribed to characterstics";
    });

  }

  void _testWrite(){ // works
    if (_connected) {

      String info = "This is a test string!"; // works
      List<int> testData1 = [];

      for(int i = 0; i < info.length; i++){
        testData1.add(info.codeUnitAt(i));
      }

      flutterReactiveBle
      .writeCharacteristicWithResponse(_rxCharacteristic, value: testData1); // Sends most consistently

      // Write charactertistic without response sends sometimes

      setState(() {
        text2 = "Command sent!";
      });

    }
  }

    void _Write(String payload){ // works
    if (_connected) {

      List<int> data = [];

      for(int i = 0; i < payload.length; i++){
        data.add(payload.codeUnitAt(i));
      }

      flutterReactiveBle
      .writeCharacteristicWithResponse(_rxCharacteristic, value: data); // Sends most consistently

      // Write charactertistic without response sends sometime

    }
  }

  void printWrapped(String text) { // for printing extrememly large strings to terminal (JWT)
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  void signInWithGoogle() async {
    // Trigger the authentication flow

    GoogleSignIn googleSignIn = await GoogleSignIn(clientId: GoogleClientId.clientId);
    
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential).then((tempUser){

      setState((){
        // print("-----1-----");
        globalUser = tempUser;
        // print(globalUser);
        // print("-----2-----");
        // //userIdText = globalUser.additionalUserInfo?.profile!["id"]; //userID is null and accessing it will throw a runtime error
        // print("-----3-----");
      });

      tempUser.user?.getIdToken(true).then((token){
        JWT = token; // make token globally accessible

        String testData = "Token should be sent here! Testing with an extremely large string. This is a new payload!";

        _Write("JTW payload: ");

        for(int i = 0; i < token.length; i+= 350){ // cannot send full JWT at one. GATT server will crash

          int end = i + 350;

          if(end > token.length){
            end = token.length;
          }

          _Write(token.substring(i,end));

        }

        _Write("JWT payload sent");

        printWrapped('user token is: ---${token}---'); // Print full JWT to terminal. Careful copying required
      });

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
                child: Text("Connect to RPI"),
              ),
              Text(text1),
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: _testRead,
                child: Text("Read Characteristic"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: _testWrite,
                child: Text("Write Characteristic"),
              ),
              Text(text2),
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: signInWithGoogle,
                child: Text("Sign in with google"),
              ),
              Text(userIdText),
            ],
          ),
       )
      )
    );
  }
}
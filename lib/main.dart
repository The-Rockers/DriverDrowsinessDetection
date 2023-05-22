// https://www.ubiqueiot.com/posts/flutter-reactive-ble
// Tutorial Reference

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
  late QualifiedCharacteristic _txCharacteristic1;
  bool isSubscribed = false;

  final Uuid serviceUuid = Uuid.parse("6e400001-b5a3-f393-e0a9-e50e24dcca9e"); // UUID for PI Gatt service
  final Uuid characteristicUuid = Uuid.parse("6e400002-b5a3-f393-e0a9-e50e24dcca9e"); // RX characterstic (Works!) 
  final Uuid characteristicUuid1 = Uuid.parse("6e400003-b5a3-f393-e0a9-e50e24dcca9e"); // TX characterstic (Works)
  final String RPIName = "rpi-gatt-server";
  // RPI device ID DC:A6:32:82:5A:50

  String text = "No devices discovered yet";
  String text1 = "No device connected yet";
  String text3 = "Not yet listening to pi data";
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

        case DeviceConnectionState.connected:
          {
            _rxCharacteristic = QualifiedCharacteristic( // Rx
                serviceId: serviceUuid, // RPI gatt service
                characteristicId: characteristicUuid, // 
                deviceId: event.deviceId);
            _txCharacteristic1 = QualifiedCharacteristic( // Tx
                serviceId: serviceUuid,
                characteristicId: characteristicUuid1,
                deviceId: event.deviceId);
            setState(() {
              text1 = "Connected to Device";
              _foundDeviceWaitingToConnect = false;
              _connected = true;
            });
            break;
          }
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

  void _Read() async{

    if(!isSubscribed){

      flutterReactiveBle.subscribeToCharacteristic(_txCharacteristic1).listen((data) {

        String response = '';

        data.forEach((value) => {response += String.fromCharCode(value)});
        print("Pi : " + response);

      }, onError: (dynamic error) {
        print("Reading error");
      });

      isSubscribed = true;

    }

    setState((){
      text3 = "Listening to Pi Data!";
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

    }
  }

  void startDetection(){
    _Write("-Start Detection-");
  }

  void stopDetection(){
    _Write("-Stop Detection-");
  }

  void downloadNewModel(){
    _Write("-Download New Model-");
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
        globalUser = tempUser;
        // //userIdText = globalUser.additionalUserInfo?.profile!["id"]; //userID is null and accessing it will throw a runtime error
      });

      tempUser.user?.getIdToken(true).then((token){
        JWT = token; // make token globally accessible

        String testData = "Token should be sent here! Testing with an extremely large string. This is a new payload!";

        _Write("-_ JWT _-");

        for(int i = 0; i < token.length; i+= 350){ // cannot send full JWT at one. GATT server will crash

          int end = i + 350;

          if(end > token.length){
            end = token.length;
          }

          _Write(token.substring(i,end));

        }

        _Write("-_ JWT _-");

        printWrapped('user token is: ---${token}---'); // Print full JWT to terminal. Careful copying required
      });

    });

  }

  void printWrapped(String text) { // for printing extrememly large strings to terminal (JWT)
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
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
                onPressed: _Read,
                child: Text("Listen to incomming data"),
              ),
              Text(text3),
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: startDetection,
                child: Text("Start Drowsiness detection"),
              ),
              Text(text2),
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: stopDetection,
                child: Text("Stop Drowsiness detection"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: downloadNewModel,
                child: Text("Download New Model"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: null,
                onPressed: signInWithGoogle,
                child: Text("Sign in and send data to backend"),
              ),
              Text(userIdText),
            ],
          ),
       )
      )
    );
  }
}
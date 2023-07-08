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
import 'dart:io' show Platform, sleep;

// Personally created pages
import 'bluetooth_page.dart';
import 'login_page.dart';
import 'scan_home_page.dart';

void main() {
   runApp (const MyApp());  
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

}

class MyAppState extends State<MyApp> {

  bool _foundDeviceWaitingToConnect = false;
  bool _scanStarted = false;
  bool _connected = false;
  bool _connecting = false;

  // Bluetooth related variables
  final flutterReactiveBle = FlutterReactiveBle();
  late DiscoveredDevice _bluetoothDevice;
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late QualifiedCharacteristic _rxCharacteristic;
  late QualifiedCharacteristic _txCharacteristic;
  bool isSubscribed = false;

  final Uuid serviceUuid = Uuid.parse("6e400001-b5a3-f393-e0a9-e50e24dcca9e"); // UUID for PI Gatt service
  final Uuid characteristicUuid = Uuid.parse("6e400002-b5a3-f393-e0a9-e50e24dcca9e"); // RX characterstic
  final Uuid characteristicUuid1 = Uuid.parse("6e400003-b5a3-f393-e0a9-e50e24dcca9e"); // TX characterstic
  final String RPIName = "rpi-gatt-server"; // Name of RPI gatt service
  // RPI device ID DC:A6:32:82:5A:50

  String text = "No devices discovered yet";
  String text1 = "No device connected yet";
  String text3 = "Not yet listening to pi data";
  String text2 = "No command sent yet";
  String userIdText = "no user id yet";
  String piResponseText = "";
  String connectionStatusText = "";

  late UserCredential? globalUser = null;
  // late String JWT;
  bool isUserLoggedIn = false;

  BuildContext? mainBuildContext;
  late State<MyApp> myAppState;

    @override
  void initState() {
    initializeFirebaseApp();
  }

  void navigateToBluetoothPage(){
    Navigator.of(mainBuildContext!).pushNamed("/bluetoothPage");
  }

  void clearPiText(){
    setState((){
      piResponseText = "";
    });
  }

  void Function() selectClearPiText(){
    return clearPiText;
  }

  void initializeFirebaseApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

    //Start bluetooth scan for avaialble devices. Bluetooth + location needs to be on for android
  void _startScan() async { // Works

    bool permGranted = false;

    setState(() {
      _scanStarted = true;
      connectionStatusText = "Starting Scan!";
    });

    LocationPermissions.PermissionStatus locationPermission;
    PermissionStatus bluetoothScanPermission;
    PermissionStatus bluetoothAdvertisePermission;
    PermissionStatus bluetoothConnectPermission;

    if (Platform.isAndroid) {
      
      /*
      For some reason, bluetooth scanning won't work unless location
      is on and paermissions are granted. No idea why.

      I need to determine which of these requests are required and which
      are not. It's relatively ambiguous at the moment.
      */

      bluetoothConnectPermission = await Permission.bluetoothConnect.request();
      bluetoothAdvertisePermission = await Permission.bluetoothAdvertise.request();
      bluetoothScanPermission = await Permission.bluetoothScan.request();
      locationPermission = await LocationPermissions.LocationPermissions().requestPermissions();

      if (locationPermission == LocationPermissions.PermissionStatus.granted) permGranted = true;

    } else if (Platform.isIOS) {
      permGranted = true;
    }
    // Main scanning logic happens here ⤵️
    if (permGranted) {
      _scanStream = flutterReactiveBle
          .scanForDevices(withServices: []).listen((device) { // Scan for all devices

            if(device.name == "rpi-gatt-server"){ // If the device is the PI
              _bluetoothDevice = device;
              _foundDeviceWaitingToConnect = true;

              //print("Device: " + device.name);
              //print("Device ID: " + device.id);

              setState(() {
                connectionStatusText = "Device Found!";
              });

              sleep(const Duration(milliseconds: 1000));
              _connectToDevice();

            }

          }); // Had to remove the onErrorBlock (threw an exception at runtime)
    }

    // sleep(const Duration(milliseconds: 50));
    // navigateToBluetoothPage();

  } 

  void Function() selectStartScan(){
    return _startScan;
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

    });

  }

  void Function() selectSignInWithGoogle(){
    return signInWithGoogle;
  }

  void _connectToDevice() {

    setState(() {
      _connecting = true;
      connectionStatusText = "Connecting to device!";
    });

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
            _txCharacteristic = QualifiedCharacteristic( // Tx
                serviceId: serviceUuid,
                characteristicId: characteristicUuid1,
                deviceId: event.deviceId);
            setState(() {
              connectionStatusText = "Connected to Device!";
              _foundDeviceWaitingToConnect = false;
              _connected = true;
              _connecting = false;
            });
            sleep(const Duration(milliseconds: 1000));
            _Read();
            navigateToBluetoothPage();
            break;
          }
        case DeviceConnectionState.disconnected:
          {
            setState(() {
              _connecting = false;
              connectionStatusText = "Not connected to Device!";
            });
            sleep(const Duration(milliseconds: 1000));
            _Read();
            navigateToBluetoothPage();
            break;
          }
        default: // none
      }
    });
  }

  void _Read() async{

    if(!isSubscribed){

      flutterReactiveBle.subscribeToCharacteristic(_txCharacteristic).listen((data) {

        String response = '';

        data.forEach((value) => {response += String.fromCharCode(value)});

        print("Pi : " + response);

        setState((){
          piResponseText += "Pi: ${response}\n";
        });

      }, onError: (dynamic error) {
        print("Reading error");
      });

      isSubscribed = true;

    }

  }

  void _Write(String payload){

    print("Writing: " + payload);

    if (_connected) {

      List<int> data = [];

      for(int i = 0; i < payload.length; i++){
        data.add(payload.codeUnitAt(i));
      }

      flutterReactiveBle
      .writeCharacteristicWithResponse(_rxCharacteristic, value: data); // Sends most consistently

    }
  }

  void printWrapped(String text) { // for printing extrememly large strings to terminal (JWT)
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  void startDetection(){
    _Write("-Start Detection-");
  }

  void Function() selectStartDetection(){
    return startDetection;
  }

  void stopDetection(){
    _Write("-Stop Detection-");
  }

  void Function() selectStopDetection(){
    return stopDetection;
  }

  void sendData(){

    if(globalUser != null){

      _Write("-Send Data-");

      globalUser!.user?.getIdToken(true).then((token){

        _Write("-_ JWT _-");

        for(int i = 0; i < token.length; i+= 350){ // cannot send full JWT at one. GATT server will crash

          int end = i + 350;

          if(end > token.length){
            end = token.length;
          }

          _Write(token.substring(i,end));

        }

        _Write("-_ JWT _-");

        printWrapped('JWT: ---${token}---'); // Print full JWT to terminal. Careful copying required

      });

    }
    else{
      signInWithGoogle();
    }
  }

  void Function() selectSendData(){
    return sendData;
  }

  void sendSignal(){
    _Write("-Send Signal-");
  }

  void Function() selectSendSignal(){
    return sendSignal;
  }

  void downloadNewModel(){
    _Write("-Download New Model-");
  }

  void Function() selectDownloadNewModel(){
    return downloadNewModel;
  }

  void signOut() async {

    GoogleSignIn googleSignIn = await GoogleSignIn(clientId: GoogleClientId.clientId);
    await googleSignIn.signOut();

    setState((){
      globalUser = null;
    });

  }

  void Function() selectSignOut(){
    return signOut;
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: "ADDDS Bluetooth App",
      home: Builder(
        builder: (BuildContext context) {
          mainBuildContext = context;
          return Center(child: 
            ScanHomePage(scan: selectStartScan, connectionStatusText: connectionStatusText)
          ,);
        },
      ),
      routes: <String, WidgetBuilder>{
        "/bluetoothPage" : (BuildContext context){
          return BluetoothPage(signIn: selectSignInWithGoogle, signOut: selectSignOut, sendData: selectSendData, sendSignal: selectSendSignal, downloadNewModel: selectDownloadNewModel, clearPiText: selectClearPiText, startDetection: selectStartDetection, stopDetection: selectStopDetection, piResponseText: piResponseText);
          },
      },
    );

  }

}
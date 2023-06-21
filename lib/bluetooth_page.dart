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

import 'main.dart';

class BluetoothPage extends StatefulWidget{

  void Function() Function()? startDetection;
  void Function() Function()? stopDetection;
  String? piResponseText;

  @override
  State<BluetoothPage> createState() => BluetoothAppState(startDetection: startDetection, stopDetection: stopDetection, piResponseText: piResponseText);

  BluetoothPage({required this.startDetection, required this.stopDetection, required this.piResponseText});
  
}

class BluetoothAppState extends State<BluetoothPage>{

  void Function() Function()? startDetection;
  void Function() Function()? stopDetection;
  String? piResponseText;

  BluetoothAppState({required this.startDetection, required this.stopDetection, required this.piResponseText});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

            body: Center(
            
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:[
                const SizedBox(height: 30),
                ElevatedButton(
                  style: null,
                  onPressed: startDetection!(),
                  child: Text("Start Drowsiness detection"),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: null,
                  onPressed: stopDetection!(),
                  child: Text("Stop Drowsiness detection"),
                ),
                const SizedBox(height: 30),
                Text(piResponseText!),
              ],
            ),
            )
    );
  }

}
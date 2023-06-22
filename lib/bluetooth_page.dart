import 'package:flutter/material.dart';

import "settings_drawer.dart";

class BluetoothPage extends StatelessWidget{

  void Function() Function()? startDetection;
  void Function() Function()? stopDetection;
  String? piResponseText;

  // For the settings drawer
  void Function() Function()? signIn;
  void Function() Function()? signOut;
  void Function() Function()? sendData;
  void Function() Function()? sendSignal;
  void Function() Function()? downloadNewModel;
  void Function() Function()? clearPiText;

  @override
  BluetoothPage({required this.startDetection, required this.stopDetection, required this.piResponseText, required this.signIn, required this.signOut, required this.sendData, required this.sendSignal, required this.downloadNewModel, required this.clearPiText});

  @override
  Widget build(BuildContext context) {

          return Scaffold(
            drawer: Drawer(
              child: SettingsDrawer(signIn: signIn, signOut: signOut, sendData: sendData, sendSignal: sendSignal, downloadNewModel: downloadNewModel, clearPiText: clearPiText),
            ),
            appBar: AppBar(
              title: const Text('ADDDS Bluetooth App'),
            ),
            body: Center(
            child:SingleChildScrollView(
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
                  Text("Pi Response(s):"),
                  const SizedBox(height: 30),
                  Text(piResponseText!),
                ],
              ),

            ),
            ),
          );

  }

}
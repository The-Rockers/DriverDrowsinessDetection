import 'package:flutter/material.dart';

class SettingsDrawer extends StatelessWidget{

  void Function() Function()? signIn;
  void Function() Function()? signOut;
  void Function() Function()? sendData;
  void Function() Function()? sendSignal;
  void Function() Function()? downloadNewModel;
  void Function() Function()? clearPiText;

  @override
  SettingsDrawer({required this.signIn, required this.signOut, required this.sendData, required this.sendSignal, required this.downloadNewModel, required this.clearPiText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child:
      Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              ElevatedButton(
                child: Text("Sign In"),
                onPressed: signIn!(),
              ),
              ElevatedButton(
                child: Text("Sign Out"),
                onPressed: signOut!(),
              ),
            ],),
            const SizedBox(height: 10),
            const Text("Developer Settings"),
            ElevatedButton(
                child: Text("Send Data"),
                onPressed: sendData!(),
            ),
            ElevatedButton(
                child: Text("Send Signal"),
                onPressed: sendSignal!(),
            ),
            ElevatedButton(
              child: Text("Get New Model"),
              onPressed: downloadNewModel!(),
            ),
            ElevatedButton(
              child: Text("Clear Pi Response(s) text"),
              onPressed: clearPiText!(),
            ),
        ]),
    ),
    );
  }

}
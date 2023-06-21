// https://www.ubiqueiot.com/posts/flutter-reactive-ble
// Tutorial Reference

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'google_clientId.dart';
// import 'dart:async';
// import 'dart:io' show Platform;

import 'bluetooth_page.dart';
import 'login_page.dart';

void main() {
  // runApp (const MyApp());

  runApp(
    MaterialApp(
      home:MyApp(),
      routes: <String, WidgetBuilder>{
        "/bluetoothPage" : (BuildContext context) => new BluetoothPage(),
      },
    )
  );

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

}

class MyAppState extends State<MyApp> {

  bool isUserLoggedIn = false;
  late UserCredential? globalUser = null; // initialize to null
  late String JWT;

  BuildContext? mainBuildContext;

    @override
  void initState() {
    initializeFirebaseApp();
  }

  void initializeFirebaseApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void signInWithGoogle() async {

    navigateToBluetoothPage(mainBuildContext!);
    return;

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
        //print(token);

        // _Write("-_ JWT _-");

        // for(int i = 0; i < token.length; i+= 350){ // cannot send full JWT at one. GATT server will crash

        //   int end = i + 350;

        //   if(end > token.length){
        //     end = token.length;
        //   }

        //   _Write(token.substring(i,end));

        // }

        // _Write("-_ JWT _-");

        // printWrapped('user token is: ---${token}---'); // Print full JWT to terminal. Careful copying required

      });

      if(globalUser != null){
        navigateToBluetoothPage(mainBuildContext!);
      }

    });

  }

  void navigateToBluetoothPage(BuildContext context){

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => BluetoothPage()),
    // );

    Navigator.of(context).pushNamed("/bluetoothPage");

  }

  void Function() selectSignInWithGoogle(){
    return signInWithGoogle;
  }

  void signOut() async {

    GoogleSignIn googleSignIn = await GoogleSignIn(clientId: GoogleClientId.clientId);
    await googleSignIn.signOut();

    setState((){
      globalUser = null;
    });

  }

  VoidCallback selectSignOut(){
    return signOut;
  }

  @override
  Widget build(BuildContext mainContext) {

    return Scaffold (
      body: Builder(
        builder: (context){
          mainBuildContext = context;
          return Scaffold(
            body: Center(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LoginPage(signIn:selectSignInWithGoogle, signOut:selectSignOut),
                  ],
                ),
           )
         );
       }
      )
    );

    // return MaterialApp (
    //   title: "ADDDS Bluetooth App",
    //   home:Scaffold(
    //     body: Center(
    //       child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: <Widget>[
    //             LoginPage(signIn:selectSignInWithGoogle, signOut:selectSignOut, mainPageContext: context),
    //           ],
    //         ),
    //    )
    //   )
    // );

  }

}
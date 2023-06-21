import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget{

  void Function() Function() signIn;
  void Function() Function() signOut;

  LoginPage({required this.signIn, required this.signOut});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [

          ElevatedButton(
            style: null,
            onPressed: signIn(),
            child: Text("Sign in"),
          ),

          ElevatedButton(
            style: null,
            onPressed: signOut(),
            child: Text("Sign out"),
          ),

        ],
      ),
    );
  }

}
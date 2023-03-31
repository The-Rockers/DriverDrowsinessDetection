import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart'; // Need 2 imports for http to work.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

import 'dart:math';
import 'dart:async';
import 'dart:convert';

import 'navigation_row.dart';
import 'drowsiness_data.dart';
import 'drowsiness_graph.dart';
import 'settings_drawer.dart';
import 'google_clientId.dart';
import 'data_response.dart'; // Importing file for HTTP response

// minor change for testing preview URL promised by firebase
// another minor change to commit

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: "antisomnus-dashboard",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {

  State<MyApp> createState() => MyAppState();

}

class MyAppState extends State<MyApp>{
  // Variables defined here are more long lasting
  int currentWeekIndex = 0;
  int currentWeekRange = 1;

  bool isBarChart = true;

  List<String> fileList = <String>['PDF', 'Excel', 'CSV', 'Txt'];
  String fileType = 'PDF'; // Needs default value to avoid crashing

  late Future<DataResponse> httpResponse;

  FirebaseAuth auth = FirebaseAuth.instance;
  late UserCredential user;

  void modifyCurrentWeekRange(){ // Alternate between 1,2, and 4 week time range.
    switch(currentWeekRange){
      case 1:
        setState((){
          currentWeekRange = 2;
        });
        break;
      case 2:
        setState((){
          currentWeekRange = 4;
        });
        break;
      case 4:
        setState((){
          currentWeekRange = 1;
        });
        break;
    }
  }

  void decrementWeekIndex(){
    setState(() {
      currentWeekIndex = (currentWeekIndex - 1) % mockData.length;
    });
  }

  void incrementWeekIndex(){
    setState(() {
      currentWeekIndex = (currentWeekIndex + 1) % mockData.length;
    });
  }

  void alternateChartType(){
    setState((){
      isBarChart = !isBarChart;
    });
  }

  void exportFile(){
    print("Selected: ${fileType}");
  }

  void changeExportFileType(String? value){
    setState(() {
      fileType = value!;
    });
  }

  void Function(String?)? selectFileType(){

    return(
      changeExportFileType
    );

  }

  Future<DataResponse> httpDataRequest() async {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));
    
    if (response.statusCode == 200){
      return DataResponse.fromJson(jsonDecode(response.body)); 
    }
    else{
      throw Exception("HTTP request failed");
    }
  }

  Future<UserCredential> signInWithGoogle() async {
  // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn(clientId: GoogleClientId.clientID).signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential user = await FirebaseAuth.instance.signInWithCredential(credential);
    print("---------------- user ------------------");
    print(user);
    print("---------------- user ------------------");
    return user;

  }

  @override
  void initState() {

    super.initState();

    httpResponse = httpDataRequest();

  }

  @override
  Widget build(BuildContext context) {
    // Variables declared here need to be redefined upon each re-render
    List<int> data = []; // For passing into DrowsinessGraph
    List<String> daysText = []; // For writing days under each entry of graph. Passed into DrowsinessGraph
    Map<int, DateTime> weeks = {}; // For collective DateTime objects for processing and indexing
    String weekText = ""; // For displaying text showing the range of weeks under graph

    for(var week = currentWeekIndex; week < (currentWeekIndex + currentWeekRange); week++){ // for the number of weeks

      int key = week % mockData.length;
      weeks[key] = mockData[key].weekStart; //Key used index for mockData

      for(int day = 0; day < 7; day++){ // for each day in the week   

        DateTime nextDate = (mockData[(week % mockData.length)].weekStart).add( Duration(days: day));
        String monthText = (nextDate.month.toString());
        String dayText = (nextDate.day.toString());

        daysText.add('${monthText}/${dayText}');
        data.add(mockData[(week % mockData.length)].drowsiness[day]);

      }

    }

    int lowestWeekIndex = (weeks.keys).reduce(min);
    int highestWeekIndex = (weeks.keys).reduce(max);

    // Write the range of weeks displayed under graph
    if(currentWeekRange == 1){
      weekText = 'Week of ${weeks[lowestWeekIndex]?.month}/${weeks[lowestWeekIndex]?.day}/${weeks[lowestWeekIndex]?.year}';
    }
    else{
      for(var i = 0; i < 2; i++){
        if(i == 0){ // From lowest week
          weekText = 'Weeks of ${weeks[lowestWeekIndex]?.month}/${weeks[lowestWeekIndex]?.day}/${weeks[lowestWeekIndex]?.year}';
        }
        else{ // To highest week
          weekText  += ' - ${weeks[highestWeekIndex]?.month}/${weeks[highestWeekIndex]?.day}/${weeks[highestWeekIndex]?.year}';
        }
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        //primarySwatch: Colors.blueGrey,
        primarySwatch: Colors.cyan,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('ADDDS Dashboard'),
          actions: <Widget>[
          ]
        ),
        // probably should refactor drawer lol
        drawer: SettingsDrawer(modifyCurrentWeekRange: modifyCurrentWeekRange, alternateChartType: alternateChartType, signInWithGoogle: signInWithGoogle,  selectFileType: selectFileType, exportFile: exportFile, fileList: fileList, fileType: fileType, isBarChart: isBarChart, currentWeekRange: currentWeekRange),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              //crossAxisAlignment: CrossAxisAlignment.stretch,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DrowsinessGraph(data:data, days:daysText, isBarChart: isBarChart), // Must make state later
                const SizedBox(height: 16),
                Text(
                  '${weekText}',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                NavigationRow(decrementWeekIndex, incrementWeekIndex),
                /*
                // testing http request future builder
                FutureBuilder<DataResponse>(
                  future: httpResponse,
                  builder: (context, snapshot){
                    if (snapshot.hasData) {
                      print(snapshot.data!.id);
                      print(snapshot.data!.title);
                      print(snapshot.data!.userId);
                      //return Text(snapshot.data!.title);
                    } else if (snapshot.hasError) {
                      //return Text('${snapshot.error}');
                    }
                    //return const CircularProgressIndicator();
                  },
                ), */
              ],// End of child list
            ),
      ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart'; // Need 2 imports for http to work.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

import 'dart:math';
import 'dart:async';
import 'dart:convert';

import 'navigation_row.dart';
import 'mock_drowsiness_data.dart'; // mock data for testing
import 'drowsiness_data.dart'; // retrieved data form firestore
import 'drowsiness_graph.dart';
import 'settings_drawer.dart';
import 'google_clientId.dart';
import 'data_response.dart'; // Importing file for HTTP response

// minor change for testing preview URL promised by firebase
// another minor change to commit

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    //name: "antisomnus-381222",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  // Variables defined here are more long lasting
  int currentWeekIndex = 0;
  int currentWeekRange = 1;

  bool isBarChart = true;

  List<String> fileList = <String>['PDF', 'Excel', 'CSV', 'Txt'];
  String fileType = 'PDF'; // Needs default value to avoid crashing

  late Future<DataResponse> httpResponse; // not used atm

  final fireStore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> fireStoreDocs = [];
  List<DrowsinessData> userDrowsinessData = mockData;

  late final UserCredential globalUser;
  String globalUserId = ""; // 100242345133661897540 userID for which there is currently data in firestore

  void modifyCurrentWeekRange() {
    // Alternate between 1,2, and 4 week time range.
    switch (currentWeekRange) {
      case 1:
        setState(() {
          currentWeekRange = 2;
        });
        break;
      case 2:
        setState(() {
          currentWeekRange = 4;
        });
        break;
      case 4:
        setState(() {
          currentWeekRange = 1;
        });
        break;
    }
  }

  void decrementWeekIndex() {
    setState(() {
      currentWeekIndex = (currentWeekIndex - 1) % userDrowsinessData.length;
    });
  }

  void incrementWeekIndex() {
    setState(() {
      currentWeekIndex = (currentWeekIndex + 1) % userDrowsinessData.length;
    });
  }

  void alternateChartType() {
    setState(() {
      isBarChart = !isBarChart;
    });
  }

  void exportFile() {
    print("Selected: ${fileType}");
  }

  void changeExportFileType(String? value) {
    setState(() {
      fileType = value!;
    });
  }

  void Function(String?)? selectFileType() {
    return (changeExportFileType);
  }

  Future<DataResponse> httpDataRequest() async {
    final response = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));

    if (response.statusCode == 200) {
      return DataResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("HTTP request failed");
    }
  }

   void signInWithGoogle() async {
    // Trigger the authentication flow
    GoogleSignIn googleSignIn = await GoogleSignIn(clientId: GoogleClientId.clientID);

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
        globalUserId = globalUser.additionalUserInfo?.profile!["id"];
      });

        print("");
        print("User credential successfully retrieved!");
        print("");

        getFirestoreData();

    });

  }

  void Function() selectSignInWithGoogle(){
    return (signInWithGoogle);
  }

  void getFirestoreData() async {

    if(globalUserId == ""){
      print("");
      print("User id in invalid. Unable to retrieve firestore data");
      print("");
    }
    else{ // user ID has been retrieved and set by signInWithGoogle()
      await fireStore.collection("users") // users collection
      .doc(globalUserId) // user id with firebase auth id
      .collection("data") // data subcollection
      .get()
      .then((event){
        for (var doc in event.docs) { // each document is 1 month
          fireStoreDocs.add(doc);
        }
      });
    }

    populateDrowsinessDataList();

  }

  void populateDrowsinessDataList(){ // works

    // add generated objects to userDrowsinessData
    String id;
    Iterable<String> weeks;
    Iterable<dynamic> tempDrowsiness = [];

    List<DateTime> weekStarts = [];
    List<List<int>> drowsiness = [];
    userDrowsinessData = []; // clear userDrowsinessData for populating with new data

    for(QueryDocumentSnapshot<Map<String, dynamic>> doc in fireStoreDocs){ // For each doc (1 month) create 1 DrowsinessData object

      List<List<String>> splitWeeks = [];
      DateTime tempWeekStart;

      weeks = doc.data().keys;
      tempDrowsiness = doc.data().values; // data for each week (list of maximum 7 ints)

      for(int i = 0; i < weeks.length; i++){ // split weeks into array of ints for creating DateTime objects
        splitWeeks.add(weeks.elementAt(i).split("-"));
      }

      for(List<String> date in splitWeeks){ // creates datetime object for each week
        int year = int.parse("20" + date[2]);
        int month = int.parse(date[0]);
        int day = int.parse(date[1]);

        tempWeekStart = DateTime(year, month, day);
        weekStarts.add(tempWeekStart);
      }

    }

    for(int i = 0; i < tempDrowsiness.length; i++){
      //print(tempDrowsiness.elementAt(i)); // List<dynamic> lol
      List<int> temp = [];
      
      for(int j = 0; j < tempDrowsiness.elementAt(i).length; j++){
        //print(tempDrowsiness.elementAt(i)[j]); // List<dynamic> lol
        temp.add(tempDrowsiness.elementAt(i)[j]);
      }

      drowsiness.add(temp);
      //print("TEMPS!!! ----------- " + temp.toString());
    }

    //print("WeekStarts!!!! ---------" + weekStarts.toString());
    //print("Drowsiness Data!!! -------------------" + drowsiness.toString());

    if(weekStarts.length != drowsiness.length){
      print("Weekstart and drowiness data length mismatch :(");
    }
    else{

      List<int> weekStartDays = [];
      List<int> sortedValues = [];

      for(int i = 0; i < weekStarts.length; i++){ // order week start elements from lowest to highest week
        weekStartDays.add(weekStarts[i].day);
      }

      weekStartDays.sort();

      for(int i = 0; i < weekStartDays.length; i++){
        sortedValues.add(weekStartDays[i]); // must use this to avoid sorting malfuction. CANNOT use .sort()
      }

        for(int i = 0; i < sortedValues.length; i++){ // at weeks from lowest - highest value
          //print(sortedValues[i]);
          for(int j = 0; j < weekStarts.length; j++){
            if(weekStarts[j].day == sortedValues[i]){
              userDrowsinessData.add(DrowsinessData(weekStart: weekStarts[j], drowsiness: drowsiness[j]));
            }
          }
        }

    }

  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Variables declared here need to be redefined upon each re-render
    List<int> data = []; // For passing into DrowsinessGraph
    List<String> daysText = []; // For writing days under each entry of graph. Passed into DrowsinessGraph
    Map<int, DateTime> weeks = {}; // For collective DateTime objects for processing and indexing
    String weekText = ""; // For displaying text showing the range of weeks under graph

    for (var week = currentWeekIndex; week < (currentWeekIndex + currentWeekRange); week++) { // for the number of weeks

      int key = week % userDrowsinessData.length;
      weeks[key] = userDrowsinessData[key].weekStart; //Key used index for userDrowsinessData

      for (int day = 0; day < userDrowsinessData[key].drowsiness.length; day++) {// for each day for which there is data in the week

        DateTime nextDate = (userDrowsinessData[(week % userDrowsinessData.length)].weekStart)
            .add(Duration(days: day));
        String monthText = (nextDate.month.toString());
        String dayText = (nextDate.day.toString());

        daysText.add('${monthText}/${dayText}');
        data.add(userDrowsinessData[(week % userDrowsinessData.length)].drowsiness[day]);
      }
    }

    int lowestWeekIndex = (weeks.keys).reduce(min);
    int highestWeekIndex = (weeks.keys).reduce(max);

    // Write the range of weeks displayed under graph
    if (currentWeekRange == 1) {
      weekText =
          'Week of ${weeks[lowestWeekIndex]?.month}/${weeks[lowestWeekIndex]?.day}/${weeks[lowestWeekIndex]?.year}';
    } else {
      for (var i = 0; i < 2; i++) {
        if (i == 0) {
          // From lowest week
          weekText =
              'Weeks of ${weeks[lowestWeekIndex]?.month}/${weeks[lowestWeekIndex]?.day}/${weeks[lowestWeekIndex]?.year}';
        } else {
          // To highest week
          weekText +=
              ' - ${weeks[highestWeekIndex]?.month}/${weeks[highestWeekIndex]?.day}/${weeks[highestWeekIndex]?.year}';
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
        appBar:
            AppBar(title: const Text('ADDDS Dashboard'), actions: <Widget>[]),
        // probably should refactor drawer lol
        drawer: SettingsDrawer(
            modifyCurrentWeekRange: modifyCurrentWeekRange,
            alternateChartType: alternateChartType,
            selectSignInWithGoogle: selectSignInWithGoogle,
            selectFileType: selectFileType,
            exportFile: exportFile,
            fileList: fileList,
            fileType: fileType,
            isBarChart: isBarChart,
            currentWeekRange: currentWeekRange),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.stretch,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DrowsinessGraph(
                  data: data,
                  days: daysText,
                  isBarChart: isBarChart), // Must make state later
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
            ], // End of child list
          ),
        ),
      ),
    );
  }
}

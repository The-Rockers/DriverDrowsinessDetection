import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:math';
import 'dart:async';

import 'navigation_row.dart';
import 'drowsiness_data.dart'; // retrieved data form firestore
import 'drowsiness_graph.dart';
import 'settings_drawer.dart';
import 'google_clientId.dart';

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

  List<String> fileList = <String>['Excel', 'CSV', 'Parquet'];
  String fileType = 'Excel'; // Needs default value to avoid crashing

  final fireStore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> fireStoreDocs = [];
  List<String> dataDocumentsID = [];
  List<DrowsinessData> userDrowsinessData = mockData; // initiaize to mock data for the time being

  late UserCredential? globalUser = null;
  String globalUserId = ""; // 100242345133661897540 | KlbEZkEFuxZqbY3qPijHdrROeks1 userID for which there is currently data in firestore (my umich acc ID)
  late bool doesUserHaveData = true; // default to true and show mock data to user

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

  /*
  void exportFile() {
    print("Selected: ${fileType}");
  }
  */

  launchURL(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri);
    
    /*
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
    */
  }

  void exportFile() async {
    // https://us-central1-antisomnus-381222.cloudfunctions.net/exportUserData?id=100242345133661897540
    //String url = 'https://us-central1-antisomnus-381222.cloudfunctions.net/exportUserData?id=${reportSignedURL}'; // get signedURL for current user

    String type = "";
    
    switch(fileType){
      case "Excel":
        type = "xls";
        break;
      case "Parquet":
        type = "prq";
        break;
      case "CSV":
        type = "csv";
    }

    //   List<String> fileList = <String>['Excel', 'CSV', 'Parquet'];

    // https://us-central1-antisomnus-381222.cloudfunctions.net/exportUserData?id=KlbEZkEFuxZqbY3qPijHdrROeks1&type=csv // example
    String url = 'https://us-central1-antisomnus-381222.cloudfunctions.net/exportUserData?id=${globalUserId}&type=${type}';
    String responseURL;

    if(globalUser == null || globalUserId == ""){ // making fewer calls to the API will save money in the long haul...
      print("No global user or global user ID is present");
      return;
    }

    final response = await http.get(Uri.parse(url));

    try{
      responseURL = jsonDecode(response.body)["url"];
    } catch(e){
      print("Error upon parsing JSON response from exporting file: ${e}");
      return;
    }

    print("export response URL: ${responseURL}");

    print("launching URL!");

    launchURL(responseURL);

  }

  void changeExportFileType(String? value) {
    setState(() {
      fileType = value!;
    });
  }

  void Function(String?)? selectFileType() {
    return (changeExportFileType);
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

      // print("----------");
      // print(tempUser);
      // print("----------");
      // tempUser contains UID which is the same ID which is gathered from JWT

      setState((){
        globalUser = tempUser;
        globalUserId = globalUser!.user!.uid; // different UID to work with JWT
        //globalUserId = globalUser?.additionalUserInfo?.profile!["id"]; // old UID that does not work with JWT
      });

      getFirestoreData();

    });

  }

  void Function() selectSignInWithGoogle(){ // for passing function to settings drawer
    return (signInWithGoogle);
  }

  void signOut(){

    if(globalUser == null){
      return;
    }

    setState((){
      globalUser = null;
      globalUserId = "";
      doesUserHaveData = false;
    });
  }

  void Function() selectSignOut(){
    return (signOut);
  }

  void getFirestoreData() async {

    fireStoreDocs = []; // clear list each time data is retrieved
    dataDocumentsID = [];
    Map<DateTime, List<int>> drowsinessDataMap = {};

    if(globalUserId == ""){
      print("");
      print("User id in invalid. Unable to retrieve firestore data");
      print("");
    }
    else{ // user ID has been retrieved and set by signInWithGoogle()

      print("userID used: " + globalUserId);

      await fireStore.collection("users") // users collection
      .doc(globalUserId) // user id with firebase auth id
      .collection("data") // data subcollection
      .get()
      .then((event) async {
        for (var day in event.docs) { // each document is 1 day (contains driver_sessions -> sessions -> different fields)

          List<String> splitDay = day.id.split("-");

          int year = int.parse(splitDay[0]);
          int month = int.parse(splitDay[1]);
          int day1 = int.parse(splitDay[2]);

          DateTime firstOfMonth = DateTime(year,month,int.parse("1"));
          
          if(!drowsinessDataMap.containsKey(firstOfMonth)){ // generate keys for entire month if first of month key IS NOT present

            DateTime tempDate = firstOfMonth;
            DateTime previousWeek;
            int weekLength = 0;
            List<int> tempDrowsinessData;

            previousWeek = firstOfMonth;

            for(int i = 1 ; i < 33; i++){

              tempDate = tempDate.add(Duration(days: 1));
              weekLength++;

              if(tempDate.month != firstOfMonth.month){
                tempDrowsinessData = List<int>.filled(weekLength, 0, growable:false);
                drowsinessDataMap[previousWeek] = tempDrowsinessData; // set key to value of new list of size weekLength initialized to 0s
                break;
              }

              if((tempDate.day - firstOfMonth.day) % 7 == 0){ // if new week
                tempDrowsinessData = List<int>.filled(weekLength, 0, growable:false);
                drowsinessDataMap[previousWeek] = tempDrowsinessData; // set key to value of new list of size weekLength initialized to 0s                previousWeek = tempDate;
                weekLength = 0;
                previousWeek = tempDate;
              }

            }

          }

          num drowsinessTotal = 0;

          await fireStore.collection("users") // users collection
          .doc(globalUserId) // user id with firebase auth id
          .collection("data") // data subcollection
          .doc(day.id)
          .collection("driver_sessions")
          .get()
          .then((event1) async {

            for (var session in event1.docs) {
              drowsinessTotal += session.data()["drowsiness_summary"]["drowsy"];
            }

          }); 

          // find index of day in drowsinessDataMap map and add total drowsiness to that index
          int dayIndex = 0;
          DateTime tempDate = DateTime(year, month, day1);

          if(drowsinessDataMap.containsKey(tempDate)){
            drowsinessDataMap[tempDate]![0] = drowsinessTotal as int;
          }
          else{

            while(true){ // either starts at 1st of month or MUST contain a previous week as key
              if(drowsinessDataMap.containsKey(tempDate)){ // this case MUST eventually be reached
                drowsinessDataMap[tempDate]![dayIndex] = drowsinessTotal as int;
                break;
              }
              else{
                tempDate = tempDate.subtract(Duration(days: 1));
                dayIndex++;
              }
            }

          }
          
        }
      });

      // print(drowsinessDataMap);

      /*
      // Compatible with old format
      await fireStore.collection("users") // users collection
      .doc(globalUserId) // user id with firebase auth id
      .collection("data") // data subcollection
      .get()
      .then((event){
        for (var doc in event.docs) { // each document is 1 month
          fireStoreDocs.add(doc);
        }
      });
      */


    }

    populateDrowsinessDataList(drowsinessDataMap);

  }

  void populateDrowsinessDataList(Map<DateTime, List<int>> drowsinessDataMap) { // Supports different days and months but NOT years (yet) Depends on how data is stored in firebase

    if(drowsinessDataMap.length == 0){
      print("There was no data found for this user! ---------");

      setState((){
        doesUserHaveData = false;
      });

      return;

    }
    else{
      setState((){
        doesUserHaveData = true;
      });
    }

    // add generated objects to userDrowsinessData
    Iterable<String> weeks;
    Iterable<dynamic> tempDrowsiness = [];

    List<DateTime> weekStarts = [];
    List<List<int>> drowsiness = [];
    userDrowsinessData = []; // clear userDrowsinessData for populating with new data

    // convert drowsinessDataMap into format compatible with previously supported format
    List<Map<String, List<int>>> drowsinessDataMapMonths = [];
    Map<String, List<int>> tempDataMap = {};
    int previousMonth = drowsinessDataMap.keys.elementAt(0).month;

    drowsinessDataMap.forEach((key, value){

        if(key.month == previousMonth){
          tempDataMap[key.toString().substring(0,10)] = value;
        }
        else{
          previousMonth = key.month;
          drowsinessDataMapMonths.add(tempDataMap);
          tempDataMap = {};
          tempDataMap[key.toString().substring(0,10)] = value;
        }

    });

    drowsinessDataMapMonths.add(tempDataMap); // month won't have been added through for loop.

    // print(drowsinessDataMapMonths);

    // for(QueryDocumentSnapshot<Map<String, dynamic>> doc in fireStoreDocs){ // For each document held in firebase (1 doc = 1 month's data)
    for(Map<String, List<int>> month in drowsinessDataMapMonths){ // For each document held in firebase (1 doc = 1 month's data)

      /*
        Retrieve the data form each document in firebase (1 doc = 1 month's data)
        and feed relevant values into weekStarts and drowsiness lists
      */

      weekStarts = []; // reset for each month's data pulled
      drowsiness = []; // reset for each month's data pulled

      List<List<String>> splitWeeks = [];
      DateTime tempWeekStart;

      weeks = month.keys; // data for each week name (month day and year)
      tempDrowsiness = month.values; // data for each week (list of maximum 7 ints)

      for(int i = 0; i < weeks.length; i++){ // split weeks into array of ints for creating DateTime objects
        splitWeeks.add(weeks.elementAt(i).split("-"));
      }

      for(List<String> date in splitWeeks){ // creates datetime object for each week
        int year = int.parse(date[0]); // assumes year comes in form "23" for 2023 for example
        int month = int.parse(date[1]);
        int day = int.parse(date[2]);

        tempWeekStart = DateTime(year, month, day);
        weekStarts.add(tempWeekStart);
      }

      for(int i = 0; i < tempDrowsiness.length; i++){ // take values from tempDrowsiness and place into drowsiness as a list of ints
        List<int> temp = [];
        
        for(int j = 0; j < tempDrowsiness.elementAt(i).length; j++){
          temp.add(tempDrowsiness.elementAt(i)[j]);
        }

        drowsiness.add(temp);
      }

      //print(weekStarts);
      //print(drowsiness);

      /*
        Sort values for each day in drowsiness list,
        generate DrowsinessData object,
        and add it to userDrowsinessData list
      */

      if(weekStarts.length != drowsiness.length){
        print("Weekstart and drowiness data length mismatch :(");
      }
      else{

        List<int> weekStartDays = [];
        List<int> sortedDaysValues = [];

        // Placing week start days values into weekStartDays and sorting 

        for(int i = 0; i < weekStarts.length; i++){ // order week start elements from lowest to highest week
          weekStartDays.add(weekStarts[i].day);
        }

        weekStartDays.sort();

        for(int i = 0; i < weekStartDays.length; i++){ // must use this to avoid sorting malfuction.
          sortedDaysValues.add(weekStartDays[i]); 
        }

        for(int i = 0; i < sortedDaysValues.length; i++){ // For each sorted day
          for(int j = 0; j < weekStarts.length; j++){ // for each weekstart entry (unordered)
            if((weekStarts[j].day == sortedDaysValues[i])){ // if the weekstart entry is of appropriate day
              setState((){
                userDrowsinessData.add(DrowsinessData(weekStart: weekStarts[j], drowsiness: drowsiness[j])); //refresh every time data is added
              });
            }
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

    // Write the range of weeks displayed under graph or write that user has no data
    
    if(doesUserHaveData){
      if (currentWeekRange == 1) {
      weekText = 'Week of ${weeks[lowestWeekIndex]?.month}/${weeks[lowestWeekIndex]?.day}/${weeks[lowestWeekIndex]?.year}';
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
    }
    else{
      weekText = "No data available";
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
            selectSignOut: selectSignOut,
            globalUser: globalUser,
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
                  isBarChart: isBarChart,
                  doesUserHaveData: doesUserHaveData,
                  ), // Must make state later
              const SizedBox(height: 16),
              Text(
                '${weekText}',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              NavigationRow(decrementWeekIndex, incrementWeekIndex),
            ], // End of child list
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'navigation_row.dart';
import 'drowsiness_data.dart';
import 'drowsiness_graph.dart';
import 'settings_drawer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {

  State<MyApp> createState() => MyAppState();

}

class MyAppState extends State<MyApp>{
  int currentWeekIndex = 0;
  int currentWeekRange = 1;

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


  @override
  Widget build(BuildContext context) {
    List<int> data = [];

    for(var week = currentWeekIndex; week < (currentWeekIndex + currentWeekRange); week++){ // for the number of weeks
      for(var day = 0; day < 7; day++){ // for each day in the week
        data.add(mockData[(week % mockData.length)].drowsiness[day]);
      }
    }

    final weekStart = mockData[currentWeekIndex].weekStart;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //home: DrowsinessGraph(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ADDDS Dashboard'),
          actions: <Widget>[
          ]
        ),
        drawer: SettingsDrawer(modifyCurrentWeekRange, currentWeekRange),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrowsinessGraph(data:data),
                const SizedBox(height: 16),
                Text(
                  'Week of ${weekStart.day}/${weekStart.month}/${weekStart.year}',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                NavigationRow(decrementWeekIndex, incrementWeekIndex),
              ],// End of child list
            ),
      ),
      ),
    );
  }
}

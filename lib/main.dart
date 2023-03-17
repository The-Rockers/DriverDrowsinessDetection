import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'drowsiness_data.dart';
import 'drowsiness_graph.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DrowsinessGraph(),
    );
  }
}

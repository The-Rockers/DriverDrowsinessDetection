import 'package:flutter/material.dart';
import 'standard_bar_chart.dart';
import 'standard_line_chart.dart';

class DrowsinessGraph extends StatelessWidget {
  List<int> data;
  List<String> days;
  final bool isBarChart;
  final bool doesUserHaveData;

  DrowsinessGraph({required this.data, required this.days, required this.isBarChart, required this.doesUserHaveData});

  @override
  Widget build(BuildContext context) {

    if(doesUserHaveData){ // if user (logged in) has data
      if(isBarChart){
        return StandardBarChart(data: data, days: days); //Keep this here
      }
      else{
        return StandardLineChart(data: data, days: days); //Keep this here
      }
    }
    else{ // if user does not have data
      data = [0];
      days = ["0/0"];
      return StandardBarChart(data: data, days: days);
    }

  }

}

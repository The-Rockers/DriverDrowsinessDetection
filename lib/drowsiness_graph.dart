import 'package:flutter/material.dart';
import 'standard_bar_chart.dart';
import 'standard_line_chart.dart';

class DrowsinessGraph extends StatelessWidget {
  final List<int> data;
  final List<String> days;
  final bool isBarChart;

  DrowsinessGraph({required this.data, required this.days, required this.isBarChart});

  @override
  Widget build(BuildContext context) {

    if(isBarChart){
      return StandardBarChart(data: data, days: days); //Keep this here
    }
    else{
      return StandardLineChart(data: data, days: days); //Keep this here
    }

  }
}
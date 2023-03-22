
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StandardBarChart extends StatelessWidget {
  final List<int> data;
  final List<String> days;

  StandardBarChart({required this.data, required this.days});

  @override
  Widget build(BuildContext context) {
    return Expanded( // This is the widget where a majority of the code is contained
      child: BarChart( // This widget causes throws a runtime exception when changing time range from 4 weeks to 1 week. Works fine though.
        BarChartData(
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: SideTitles(
              showTitles: true,
              margin: 12,
              getTextStyles: (context, value) => const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            bottomTitles: SideTitles(
              showTitles: true,
              margin: 8,
              getTextStyles: (context, value) => const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              getTitles: (double value) {
                return days[value.toInt()];
              },
            ),
          ),
          // Takes in the data list and converts it to a list of BarChartRodData widgets
          barGroups: data
              .asMap()
              .map((index, value) => MapEntry(
                    index,
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          y: value.toDouble(),
                          colors: [Colors.cyan],
                          width: 8,
                        ),
                      ],
                    ),
                  ))
              .values
              .toList(),
        ),
      ),
      ); //
  }
}
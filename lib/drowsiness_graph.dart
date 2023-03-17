import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DrowsinessGraph extends StatelessWidget {
  final List<int> data;

  DrowsinessGraph({required this.data});

  @override
  Widget build(BuildContext context) {

    return Expanded( // This is the widget where a majority of the code is contained
      child: BarChart(
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
                return 'D${value.toInt() + 1}';
              },
            ),
          ),
          barGroups: data
              .asMap()
              .map((index, value) => MapEntry(
                    index,
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          y: value.toDouble(),
                          colors: [Colors.blueGrey],
                          width: 20,
                        ),
                      ],
                    ),
                  ))
              .values
              .toList(),
        ),
      ),
      ); // Keep this here

  }
}
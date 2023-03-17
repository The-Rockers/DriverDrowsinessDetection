import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'drowsiness_data.dart';
import 'settings_drawer.dart';
import 'navigation_row.dart';

class DrowsinessGraph extends StatefulWidget {
  const DrowsinessGraph({super.key});

  @override
  _DrowsinessGraphState createState() => _DrowsinessGraphState();
}

class _DrowsinessGraphState extends State<DrowsinessGraph> {
  int currentWeekIndex = 0;

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
    final data = mockData[currentWeekIndex].drowsiness;
    final weekStart = mockData[currentWeekIndex].weekStart;

    return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded( // This is the widget where a majority of the code is contained
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
                ),
                const SizedBox(height: 16),
                Text(
                  'Week of ${weekStart.day}/${weekStart.month}/${weekStart.year}',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                NavigationRow(decrementWeekIndex, incrementWeekIndex),
              ],
            ),
      );
  }
}
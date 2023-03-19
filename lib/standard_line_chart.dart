import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StandardLineChart extends StatelessWidget {
  final List<int> data;
  final List<String> days;

  StandardLineChart({required this.data, required this.days});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double xCoorSpacing = (screenWidth - 300) / data.length;

    return Expanded(
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(enabled: false),
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
          lineBarsData: [
              LineChartBarData(
                spots: data.
                  asMap()
                  .entries.map((entry) => FlSpot((entry.key.toDouble() * 1), entry.value.toDouble())) // wants x and Y coor of point
                  .toList(),
                isCurved: true,
                dotData: FlDotData(
                  show: true,
                ),
                colors: [Colors.blue]
              ),
          ],
          borderData: FlBorderData(
            border: const Border(bottom: BorderSide(), left: BorderSide())
          ),
        ),
      ),
    );
  }
}
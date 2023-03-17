class DrowsinessData {
  final DateTime weekStart;
  final List<int> drowsiness;

  DrowsinessData({required this.weekStart, required this.drowsiness});
}

List<DrowsinessData> mockData = [
  DrowsinessData(
    weekStart: DateTime(2023, 3, 6),
    drowsiness: [1,2,3,4,5,6,7],
  ),
  DrowsinessData(
    weekStart: DateTime(2023, 2, 27),
    drowsiness: [1, 0, 2, 4, 3, 1, 0],
  ),
  // Add more data if needed
];

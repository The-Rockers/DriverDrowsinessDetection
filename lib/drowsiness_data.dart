class DrowsinessData {
  final DateTime weekStart;
  final List<int> drowsiness;

  DrowsinessData({required this.weekStart, required this.drowsiness});
}

List<DrowsinessData> mockData = [
  DrowsinessData(
    weekStart: DateTime(2023, 3, 6),
    drowsiness: [2, 5, 3, 1, 4, 0, 0, 5, 14,3,14,2,15,6],
  ),
  DrowsinessData(
    weekStart: DateTime(2023, 2, 27),
    drowsiness: [1, 0, 2, 4, 3, 1, 0],
  ),
  // Add more data if needed
];

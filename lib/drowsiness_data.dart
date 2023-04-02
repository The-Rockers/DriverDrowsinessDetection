class DrowsinessData {
  final DateTime weekStart;
  final List<int> drowsiness;

  DrowsinessData({required this.weekStart, required this.drowsiness});
}

List<DrowsinessData> mockData = [
  // Information should always start from lowest date and go to latest date
  DrowsinessData(
    weekStart: DateTime(2023, 2, 13),
    drowsiness: [13, 11,9, 7, 5, 3, 1],
  ),
  DrowsinessData(
    weekStart: DateTime(2023, 2, 20),
    drowsiness: [1, 3, 5, 7, 9, 11, 13],
  ),
  DrowsinessData(
    weekStart: DateTime(2023, 2, 27),
    drowsiness: [7, 6, 5, 4, 3, 2, 1],
  ),
  DrowsinessData(
    weekStart: DateTime(2023, 3, 6),
    drowsiness: [1,2,3,4,5,6,7],
  ),
];
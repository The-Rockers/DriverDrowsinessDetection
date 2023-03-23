class DataResponse {
  final int userId;
  final int id;
  final String title;

  const DataResponse({
    required this.userId,
    required this.id,
    required this.title,
  });

  factory DataResponse.fromJson(Map<String, dynamic> json) {
    return DataResponse(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
    );
  }
}
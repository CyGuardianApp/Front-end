class Department {
  final String id;
  final String name;
  final String description;
  final String headId;
  final List<String> questionnaireIds;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.headId,
    required this.questionnaireIds,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      headId: json['headId'],
      questionnaireIds: List<String>.from(json['questionnaireIds']),
    );
  }
}

class RiskAssessment {
  final String id;
  final String departmentId;
  final double riskValue;
  final String aiReportId;
  final RiskStatus status;
  final DateTime createdAt;
  final List<String> recommendations;
  final double estimatedCost;

  RiskAssessment({
    required this.id,
    required this.departmentId,
    required this.riskValue,
    required this.aiReportId,
    required this.status,
    required this.createdAt,
    required this.recommendations,
    required this.estimatedCost,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      id: json['id'],
      departmentId: json['departmentId'],
      riskValue: json['riskValue'].toDouble(),
      aiReportId: json['aiReportId'],
      status: RiskStatus.values.firstWhere(
        (status) => status.toString() == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      recommendations: List<String>.from(json['recommendations']),
      estimatedCost: json['estimatedCost'].toDouble(),
    );
  }
}

enum RiskStatus {
  pending,
  approved,
  rejected,
}

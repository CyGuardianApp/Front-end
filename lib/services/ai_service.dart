import 'dart:convert';
import '../models/company_history.dart';

class AIService {
  // In a real application, this would be an API endpoint
  static const String _endpoint = 'https://api.example.com/ai';

  // For demonstration purposes, we'll simulate API calls
  Future<Map<String, dynamic>> generateRiskAssessment(
    CompanyHistory companyHistory,
    List<Map<String, dynamic>> questionnaireResponses,
  ) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Convert company history to the format needed for AI analysis
    final companyData = companyHistory.toAIAnalysisFormat();

    // In a real implementation, we would send companyData and questionnaireResponses
    // to an AI service and get back a risk assessment

    // For demonstration, we'll generate a risk score based on some factors
    int riskScore = 50; // Base risk score

    // Adjust based on security tools
    if (companyHistory.toolId.isNotEmpty) {
      riskScore -= 3; // Reduce risk if security tool is present
    }

    // Adjust based on policy documents
    if (companyHistory.policyId.isNotEmpty) {
      riskScore -= 2; // Reduce risk if policy document is present
    }

    // Adjust based on incidents
    if (companyHistory.incidentId.isNotEmpty) {
      riskScore += 5; // Increase risk if incident is recorded
    }

    // Ensure risk score is within bounds
    riskScore = riskScore.clamp(10, 90);

    // Determine risk level based on score
    String riskLevel;
    if (riskScore < 40) {
      riskLevel = 'Low';
    } else if (riskScore < 70) {
      riskLevel = 'Medium';
    } else {
      riskLevel = 'High';
    }

    // Generate mock recommendations based on data
    List<Map<String, dynamic>> findings = [];

    // Check for security tool categories
    bool hasFw = false, hasAv = false, hasIdp = false;

    if (companyHistory.toolId.isNotEmpty) {
      String toolCategory = companyHistory.toolCategory.toLowerCase();
      if (toolCategory.contains('firewall')) hasFw = true;
      if (toolCategory.contains('antivirus')) hasAv = true;
      if (toolCategory.contains('identity')) hasIdp = true;
    }

    if (!hasFw) {
      findings.add({
        'id': '1',
        'category': 'Network Security',
        'description': 'No firewall solution detected',
        'severity': 'High',
        'recommendation': 'Implement a next-generation firewall solution',
        'estimatedCost': 12000,
      });
    }

    if (!hasAv) {
      findings.add({
        'id': '2',
        'category': 'Endpoint Security',
        'description': 'No antivirus solution detected',
        'severity': 'High',
        'recommendation': 'Deploy enterprise antivirus software',
        'estimatedCost': 8000,
      });
    }

    if (!hasIdp) {
      findings.add({
        'id': '3',
        'category': 'Access Control',
        'description': 'No identity management solution detected',
        'severity': 'Medium',
        'recommendation': 'Implement an identity and access management system',
        'estimatedCost': 15000,
      });
    }

    // Add some generic findings
    findings.add({
      'id': '4',
      'category': 'Security Training',
      'description': 'Employee security awareness training needed',
      'severity': 'Medium',
      'recommendation': 'Conduct quarterly security training sessions',
      'estimatedCost': 5000,
    });

    findings.add({
      'id': '5',
      'category': 'Incident Response',
      'description': 'Formalized incident response plan needed',
      'severity': 'Medium',
      'recommendation': 'Develop and test an incident response plan',
      'estimatedCost': 7000,
    });

    // Calculate total remediation cost - FIXED
    double totalRemediationCost = 0.0;
    for (var finding in findings) {
      totalRemediationCost += (finding['estimatedCost'] as num).toDouble();
    }

    return {
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'findings': findings,
      'totalRemediationCost': totalRemediationCost,
      'timestamp': DateTime.now().toIso8601String(),
      'projectedRiskScoreAfterRemediation': (riskScore * 0.7).round(),
    };
  }

  Future<String> generateReport({
    required double riskValue,
    required List<String> recommendations,
    required double estimatedCost,
    required String departmentData,
  }) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 3));

    // In a real application, this would generate a PDF report
    // For demonstration, we'll return a JSON string
    final reportData = {
      'riskValue': riskValue,
      'recommendations': recommendations,
      'estimatedCost': estimatedCost,
      'departmentData': departmentData,
      'generatedAt': DateTime.now().toIso8601String(),
    };

    return jsonEncode(reportData);
  }
}

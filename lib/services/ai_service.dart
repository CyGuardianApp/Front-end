import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/company_history.dart';
import '../services/http_service.dart';
import '../services/token_service.dart';
import '../config/api_config.dart';

class AIService {
  /// Generate risk assessment using AI service
  Future<Map<String, dynamic>> generateRiskAssessment(
    CompanyHistory companyHistory,
    List<Map<String, dynamic>> questionnaireResponses,
  ) async {
    try {
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        throw ApiException('Authentication required for AI analysis');
      }

      // Prepare data for AI analysis
      final analysisData = {
        'company_history': companyHistory.toAIAnalysisFormat(),
        'questionnaire_responses': questionnaireResponses,
        'analysis_type': 'comprehensive_risk_assessment',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await HttpService.post(
        ApiConfig.buildUrl('/ai/risk-assessment'),
        accessToken: accessToken,
        body: analysisData,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Validate response structure
        if (result is Map<String, dynamic> &&
            result.containsKey('riskScore') &&
            result.containsKey('riskLevel')) {
          return result;
        } else {
          throw ApiException('Invalid AI service response format');
        }
      } else {
        throw ApiException('AI service returned error: ${response.statusCode}');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('AI service error: $e');
      }

      // Fallback to mock data if AI service is unavailable
      return _generateFallbackRiskAssessment(
          companyHistory, questionnaireResponses);
    }
  }

  /// Generate PDF report using AI service
  Future<String> generateReport({
    required double riskValue,
    required List<String> recommendations,
    required double estimatedCost,
    required String departmentData,
  }) async {
    try {
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        throw ApiException('Authentication required for report generation');
      }

      final reportData = {
        'risk_value': riskValue,
        'recommendations': recommendations,
        'estimated_cost': estimatedCost,
        'department_data': departmentData,
        'report_type': 'comprehensive_security_report',
        'format': 'pdf',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await HttpService.post(
        ApiConfig.buildUrl('/ai/generate-report'),
        accessToken: accessToken,
        body: reportData,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Return the report URL or content
        return result['report_url'] ?? result['report_content'] ?? '';
      } else {
        throw ApiException('Report generation failed: ${response.statusCode}');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Report generation error: $e');
      }

      // Fallback to mock report
      return _generateFallbackReport(
        riskValue: riskValue,
        recommendations: recommendations,
        estimatedCost: estimatedCost,
        departmentData: departmentData,
      );
    }
  }

  /// Get AI service health status
  Future<bool> isHealthy() async {
    try {
      final response = await HttpService.get(
        ApiConfig.buildUrl('/ai/health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('AI service health check failed: $e');
      }
      return false;
    }
  }

  /// Get AI service status with detailed information
  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final response = await HttpService.get(
        ApiConfig.buildUrl('/ai/status'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'healthy',
          'service': 'ai-service',
          'version': data['version'] ?? 'unknown',
          'capabilities': data['capabilities'] ?? [],
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'status': 'unhealthy',
          'error': 'HTTP ${response.statusCode}',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Fallback risk assessment when AI service is unavailable
  Map<String, dynamic> _generateFallbackRiskAssessment(
    CompanyHistory companyHistory,
    List<Map<String, dynamic>> questionnaireResponses,
  ) {
    if (kDebugMode) {
      print('Using fallback risk assessment - AI service unavailable');
    }

    // Calculate risk score based on available data
    int riskScore = 50; // Base risk score

    // Adjust based on security tools
    if (companyHistory.toolId.isNotEmpty) {
      riskScore -= 3;
    }

    // Adjust based on policy documents
    if (companyHistory.policyId.isNotEmpty) {
      riskScore -= 2;
    }

    // Adjust based on incidents
    if (companyHistory.incidentId.isNotEmpty) {
      riskScore += 5;
    }

    // Adjust based on questionnaire responses
    for (var response in questionnaireResponses) {
      if (response['risk_indicators'] != null) {
        riskScore += (response['risk_indicators'] as int? ?? 0);
      }
    }

    // Ensure risk score is within bounds
    riskScore = riskScore.clamp(10, 90);

    // Determine risk level
    String riskLevel;
    if (riskScore < 40) {
      riskLevel = 'Low';
    } else if (riskScore < 70) {
      riskLevel = 'Medium';
    } else {
      riskLevel = 'High';
    }

    // Generate findings
    List<Map<String, dynamic>> findings =
        _generateFallbackFindings(companyHistory);

    // Calculate total remediation cost
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
      'fallback_mode': true,
      'note': 'AI service unavailable - using fallback analysis',
    };
  }

  /// Generate fallback findings
  List<Map<String, dynamic>> _generateFallbackFindings(
      CompanyHistory companyHistory) {
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

    // Add generic findings
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

    return findings;
  }

  /// Generate fallback report
  String _generateFallbackReport({
    required double riskValue,
    required List<String> recommendations,
    required double estimatedCost,
    required String departmentData,
  }) {
    final reportData = {
      'riskValue': riskValue,
      'recommendations': recommendations,
      'estimatedCost': estimatedCost,
      'departmentData': departmentData,
      'generatedAt': DateTime.now().toIso8601String(),
      'fallback_mode': true,
      'note': 'AI service unavailable - using fallback report generation',
    };

    return jsonEncode(reportData);
  }
}

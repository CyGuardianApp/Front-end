import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/company_history.dart';
import '../providers/questionnaire_provider.dart';

class RiskAssessmentProvider extends ChangeNotifier {
  final AIService _aiService;
  final List<Map<String, dynamic>> _questionnaires = [];
  CompanyHistory? _companyHistory;
  Map<String, dynamic>? _aiReport;
  bool _isLoading = false;
  String? _errorMessage;

  RiskAssessmentProvider(this._aiService);

  List<Map<String, dynamic>> get questionnaires => _questionnaires;
  CompanyHistory? get companyHistory => _companyHistory;
  Map<String, dynamic>? get aiReport => _aiReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setCompanyHistory(CompanyHistory? history) {
    _companyHistory = history;
    notifyListeners();
  }

  /// Generate AI risk assessment from questionnaire response ID (new method)
  Future<void> generateAIReportFromResponse(String questionnaireResponseId,
      {String? departmentId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final riskAssessment = await _aiService.generateRiskAssessmentFromDB(
        questionnaireResponseId,
        departmentId: departmentId,
      );

      _aiReport = riskAssessment;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to generate AI report: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Generate AI risk assessment (legacy method - kept for compatibility)
  Future<void> generateAIReport() async {
    if (_companyHistory == null) {
      _errorMessage =
          'Company history not available. Please add company details first.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<Map<String, dynamic>> questionnaireResponses = [];

      final riskAssessment = await _aiService.generateRiskAssessment(
        _companyHistory!,
        questionnaireResponses,
      );

      _aiReport = riskAssessment;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to generate AI report. Please try again.';
      notifyListeners();
    }
  }

  Future<bool> approveAIReport(bool approved, String? comments) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (approved) {
        _aiReport = {
          ..._aiReport!,
          'status': 'Approved',
          'approvedAt': DateTime.now().toIso8601String(),
          'comments': comments,
        };
      } else {
        _aiReport = {
          ..._aiReport!,
          'status': 'Rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
          'comments': comments,
        };
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to process approval. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitQuestionnaire(
      String questionnaireId, List<Map<String, dynamic>> answers) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final index =
          _questionnaires.indexWhere((q) => q['id'] == questionnaireId);
      if (index != -1) {
        for (var answer in answers) {
          final questionIndex = _questionnaires[index]['questions']
              .indexWhere((q) => q['id'] == answer['id']);
          if (questionIndex != -1) {
            _questionnaires[index]['questions'][questionIndex]['answer'] =
                answer['answer'];
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to submit questionnaire. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Load latest APPROVED risk assessment for dashboard
  Future<void> loadLatestRiskAssessment(
      QuestionnaireProvider? questionnaireProvider) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Only fetch APPROVED risk assessments for dashboard
      final riskAssessments =
          await _aiService.fetchRiskAssessments(status: 'approved');

      if (riskAssessments.isNotEmpty) {
        // Sort by created date (newest first) and use the latest one
        riskAssessments.sort((a, b) {
          final dateA = DateTime.parse(a['createdAt']);
          final dateB = DateTime.parse(b['createdAt']);
          return dateB.compareTo(dateA);
        });

        _aiReport = riskAssessments.first;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // No approved risk assessments available
      _aiReport = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load risk assessment: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load pending AI reports for AI report screen
  Future<List<Map<String, dynamic>>> loadPendingReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final riskAssessments =
          await _aiService.fetchRiskAssessments(status: 'pending');
      _isLoading = false;
      notifyListeners();
      return riskAssessments;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load pending reports: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  /// Load approved reports for approval screen
  Future<List<Map<String, dynamic>>> loadApprovedReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final riskAssessments =
          await _aiService.fetchRiskAssessments(status: 'approved');
      _isLoading = false;
      notifyListeners();
      return riskAssessments;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load approved reports: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  /// Approve a risk assessment
  Future<bool> approveRiskAssessment(
      String riskAssessmentId, bool approved) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _aiService.approveRiskAssessment(riskAssessmentId, approved);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to approve risk assessment: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/questionnaire.dart';
import 'auth_provider.dart';

class QuestionnaireProvider with ChangeNotifier {
  final String baseUrl = AuthService.apiBaseUrl;

  List<Questionnaire> _questionnaires = [];
  List<QuestionnaireResponse> _responses = [];
  final Map<String, Map<String, Map<String, dynamic>>> _draftResponses = {};

  bool _isLoading = false;
  bool _isFetchingQuestionnaires = false;
  bool _isFetchingResponses = false;
  String? _errorMessage;

  List<Questionnaire> get questionnaires => _questionnaires;
  List<QuestionnaireResponse> get responses => _responses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Map<String, dynamic> _createSafeQuestionnaireData(
      Questionnaire questionnaire) {
    try {
      return {
        'id': questionnaire.id,
        'title': questionnaire.title,
        'description': questionnaire.description,
        'department_id': questionnaire.departmentId,
        'created_by': questionnaire.createdBy,
        'created_at': questionnaire.createdAt.toIso8601String(),
        'questions': questionnaire.questions
            .map((q) => _createSafeQuestionData(q))
            .toList(),
        'status': questionnaire.status.toString().split('.').last,
      };
    } catch (e) {
      debugPrint('Error in _createSafeQuestionnaireData: $e');
      // Return a minimal safe version
      return {
        'id': questionnaire.id,
        'title': questionnaire.title,
        'description': questionnaire.description,
        'department_id': questionnaire.departmentId,
        'created_by': questionnaire.createdBy,
        'created_at': DateTime.now().toIso8601String(),
        'questions': [],
        'status': 'draft',
      };
    }
  }

  // Create body for update endpoint (backend reads id from path; created_at is server-side)
  Map<String, dynamic> _createUpdateQuestionnaireData(
      Questionnaire questionnaire) {
    final data = _createSafeQuestionnaireData(questionnaire);
    data.remove('id');
    data.remove('created_at');
    return data;
  }

  Map<String, dynamic> _createSafeQuestionData(Question question) {
    try {
      dynamic safeAnswer = question.answer;

      // Handle DateTime conversion
      if (safeAnswer is DateTime) {
        safeAnswer = safeAnswer.toIso8601String();
      }

      // Handle other non-serializable objects
      if (safeAnswer != null && !_isJsonSerializable(safeAnswer)) {
        safeAnswer = safeAnswer.toString();
      }

      return {
        'id': question.id,
        'text': question.text,
        'type': question.type.toString().split('.').last,
        'options': question.options,
        'answer': safeAnswer,
        'required': question.required,
      };
    } catch (e) {
      debugPrint('Error in _createSafeQuestionData: $e');
      // Return a minimal safe version
      return {
        'id': question.id,
        'text': question.text,
        'type': 'text',
        'options': null,
        'answer': null,
        'required': true,
      };
    }
  }

  bool _isJsonSerializable(dynamic value) {
    try {
      return value is String ||
          value is int ||
          value is double ||
          value is bool ||
          value == null ||
          (value is List && value.every((item) => _isJsonSerializable(item))) ||
          (value is Map &&
              value.keys.every((key) => key is String) &&
              value.values.every((value) => _isJsonSerializable(value)));
    } catch (e) {
      debugPrint('Error in _isJsonSerializable: $e');
      return false;
    }
  }

  Future<bool> createQuestionnaire(
      Questionnaire questionnaire, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.accessToken == null) {
        _errorMessage = 'Authentication required';
        return false;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.accessToken}',
      };

      // Debug: Try to encode the questionnaire and catch any errors
      String jsonBody;
      try {
        // Create a safe version of the questionnaire data
        final safeData = _createSafeQuestionnaireData(questionnaire);
        jsonBody = jsonEncode(safeData);
        debugPrint('JSON Body: $jsonBody');
      } catch (e) {
        debugPrint('JSON Encoding Error: $e');
        _errorMessage = 'Failed to encode questionnaire data: $e';
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/questionnaires/'),
        headers: headers,
        body: jsonBody,
      );

      // Debug: Print response status and body
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newQ = Questionnaire.fromJson(jsonDecode(response.body));
        _questionnaires.add(newQ);
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) {
          _errorMessage = errorData['detail'];
        } else {
          _errorMessage = 'Error: ${response.body}';
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Exception: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateQuestionnaire(
      Questionnaire questionnaire, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.accessToken == null) {
        _errorMessage = 'Authentication required';
        return false;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.accessToken}',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/questionnaires/${questionnaire.id}'),
        headers: headers,
        body: jsonEncode(_createUpdateQuestionnaireData(questionnaire)),
      );

      if (response.statusCode == 200) {
        final index =
            _questionnaires.indexWhere((q) => q.id == questionnaire.id);
        if (index != -1) _questionnaires[index] = questionnaire;
        return true;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['detail'] != null) {
            _errorMessage = errorData['detail'];
          } else {
            _errorMessage = 'Error: ${response.body}';
          }
        } catch (_) {
          _errorMessage = 'Failed to update (${response.statusCode})';
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Exception: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllQuestionnaires(BuildContext context) async {
    if (_isFetchingQuestionnaires) return; // Prevent duplicate requests

    _isLoading = true;
    _isFetchingQuestionnaires = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.accessToken == null) {
        _errorMessage = 'Authentication required';
        return;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.accessToken}',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/questionnaires/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        debugPrint('Received ${data.length} questionnaires from backend');
        for (var item in data) {
          debugPrint('  Raw questionnaire data: $item');
        }
        _questionnaires = data.map((e) => Questionnaire.fromJson(e)).toList();
        debugPrint('Parsed ${_questionnaires.length} questionnaires');
        for (var q in _questionnaires) {
          debugPrint(
              '  Parsed questionnaire: ID=${q.id}, Title=${q.title}, Status=${q.status}');
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) {
          _errorMessage = errorData['detail'];
        } else {
          _errorMessage = 'Failed to load: ${response.statusCode}';
        }
      }
    } catch (e) {
      _errorMessage = 'Exception: $e';
    } finally {
      _isLoading = false;
      _isFetchingQuestionnaires = false;
      notifyListeners();
    }
  }

  Questionnaire? getQuestionnaireById(String id) {
    try {
      return _questionnaires.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraftResponses(String questionnaireId, String userId,
      Map<String, dynamic> responses) async {
    _draftResponses.putIfAbsent(questionnaireId, () => {});
    _draftResponses[questionnaireId]![userId] = Map.from(responses);
  }

  Map<String, dynamic>? getDraftResponses(
      String questionnaireId, String userId) {
    return _draftResponses[questionnaireId]?[userId];
  }

  void clearDraftResponses(String questionnaireId, String userId) {
    _draftResponses[questionnaireId]?.remove(userId);
  }

  Future<bool> submitResponse(
      QuestionnaireResponse response, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.accessToken == null) {
        _errorMessage = 'Authentication required';
        return false;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.accessToken}',
      };

      final res = await http.post(
        Uri.parse('$baseUrl/questionnaire_responses/'),
        headers: headers,
        body: jsonEncode(response.toJson()),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _responses.add(response);
        return true;
      } else {
        final errorData = jsonDecode(res.body);
        if (errorData['detail'] != null) {
          _errorMessage = errorData['detail'];
        } else {
          _errorMessage = 'Failed to submit: ${res.body}';
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Exception: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  QuestionnaireResponse? getLatestResponse(
      String questionnaireId, String userId) {
    try {
      final responses = _responses
          .where((r) =>
              r.questionnaireId == questionnaireId && r.respondentId == userId)
          .toList();
      if (responses.isEmpty) return null;
      responses.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return responses.first;
    } catch (_) {
      return null;
    }
  }

  QuestionnaireResponse? getResponseById(String responseId) {
    try {
      return _responses.firstWhere((r) => r.id == responseId);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAllResponses(BuildContext context) async {
    if (_isFetchingResponses) return; // Prevent duplicate requests

    _isLoading = true;
    _isFetchingResponses = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.accessToken == null) {
        _errorMessage = 'Authentication required';
        return;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.accessToken}',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/questionnaire_responses/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _responses =
            data.map((e) => QuestionnaireResponse.fromJson(e)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) {
          _errorMessage = errorData['detail'];
        } else {
          _errorMessage = 'Failed to load responses';
        }
      }
    } catch (e) {
      _errorMessage = 'Exception: $e';
    } finally {
      _isLoading = false;
      _isFetchingResponses = false;
      notifyListeners();
    }
  }
}

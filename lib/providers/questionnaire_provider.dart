import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/http_service.dart';
import '../services/token_service.dart';
import '../config/api_config.dart';
import '../models/questionnaire.dart';

class QuestionnaireProvider with ChangeNotifier {
  final String baseUrl = ApiConfig.apiBaseUrl;

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
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create a safe version of the questionnaire data
      final safeData = _createSafeQuestionnaireData(questionnaire);

      if (kDebugMode) {
        debugPrint('Creating questionnaire with data: ${jsonEncode(safeData)}');
      }

      final response = await HttpService.post(
        ApiConfig.questionnaires,
        accessToken: accessToken,
        body: safeData,
      );

      if (kDebugMode) {
        debugPrint('Response Status: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newQ = Questionnaire.fromJson(jsonDecode(response.body));
        _questionnaires.add(newQ);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to create questionnaire';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        debugPrint('Create questionnaire API error: ${e.message}');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      _errorMessage = 'Request timeout. The server took too long to respond. Please try again.';
      if (kDebugMode) {
        debugPrint('Create questionnaire timeout: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      _errorMessage = 'Network error. Please check your internet connection and ensure the server is running.';
      if (kDebugMode) {
        debugPrint('Create questionnaire network error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create questionnaire: ${e.toString()}';
      if (kDebugMode) {
        debugPrint('Create questionnaire error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuestionnaire(
      Questionnaire questionnaire, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await HttpService.put(
        ApiConfig.buildUrlWithParams(
            ApiConfig.questionnaireById, {'id': questionnaire.id}),
        accessToken: accessToken,
        body: _createUpdateQuestionnaireData(questionnaire),
      );

      if (response.statusCode == 200) {
        final index =
            _questionnaires.indexWhere((q) => q.id == questionnaire.id);
        if (index != -1) _questionnaires[index] = questionnaire;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to update questionnaire';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        debugPrint('Update questionnaire API error: ${e.message}');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      _errorMessage = 'Request timeout. The server took too long to respond. Please try again.';
      if (kDebugMode) {
        debugPrint('Update questionnaire timeout: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      _errorMessage = 'Network error. Please check your internet connection and ensure the server is running.';
      if (kDebugMode) {
        debugPrint('Update questionnaire network error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update questionnaire: ${e.toString()}';
      if (kDebugMode) {
        debugPrint('Update questionnaire error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAllQuestionnaires(BuildContext context) async {
    if (_isFetchingQuestionnaires) return; // Prevent duplicate requests

    _isLoading = true;
    _isFetchingQuestionnaires = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        _isFetchingQuestionnaires = false;
        notifyListeners();
        return;
      }

      final response = await HttpService.get(
        ApiConfig.questionnaires,
        accessToken: accessToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (kDebugMode) {
          debugPrint('Received ${data.length} questionnaires from backend');
          for (var item in data) {
            debugPrint('  Raw questionnaire data: $item');
          }
        }
        _questionnaires = data.map((e) => Questionnaire.fromJson(e)).toList();
        if (kDebugMode) {
          debugPrint('Parsed ${_questionnaires.length} questionnaires');
          for (var q in _questionnaires) {
            debugPrint(
                '  Parsed questionnaire: ID=${q.id}, Title=${q.title}, Status=${q.status}');
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to load questionnaires';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        debugPrint('Fetch questionnaires API error: ${e.message}');
      }
    } on TimeoutException catch (e) {
      _errorMessage = 'Request timeout. The server took too long to respond. Please try again.';
      if (kDebugMode) {
        debugPrint('Fetch questionnaires timeout: $e');
      }
    } on SocketException catch (e) {
      _errorMessage = 'Network error. Please check your internet connection and ensure the server is running.';
      if (kDebugMode) {
        debugPrint('Fetch questionnaires network error: $e');
      }
    } catch (e) {
      _errorMessage = 'Failed to load questionnaires: ${e.toString()}';
      if (kDebugMode) {
        debugPrint('Fetch questionnaires error: $e');
      }
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
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final res = await HttpService.post(
        ApiConfig.questionnaireResponses,
        accessToken: accessToken,
        body: response.toJson(),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Parse the response to get the backend-generated ID
        final responseData = jsonDecode(res.body);
        final updatedResponse = QuestionnaireResponse.fromJson(responseData);
        _responses.add(updatedResponse);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(res.body);
        _errorMessage = errorData['detail'] ?? 'Failed to submit response';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        debugPrint('Submit response API error: ${e.message}');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on TimeoutException catch (e) {
      _errorMessage = 'Request timeout. The server took too long to respond. Please try again.';
      if (kDebugMode) {
        debugPrint('Submit response timeout: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      _errorMessage = 'Network error. Please check your internet connection and ensure the server is running.';
      if (kDebugMode) {
        debugPrint('Submit response network error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit response: ${e.toString()}';
      if (kDebugMode) {
        debugPrint('Submit response error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
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
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        _isFetchingResponses = false;
        notifyListeners();
        return;
      }

      final response = await HttpService.get(
        ApiConfig.questionnaireResponses,
        accessToken: accessToken,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _responses =
            data.map((e) => QuestionnaireResponse.fromJson(e)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to load responses';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        debugPrint('Fetch responses API error: ${e.message}');
      }
    } on TimeoutException catch (e) {
      _errorMessage = 'Request timeout. The server took too long to respond. Please try again.';
      if (kDebugMode) {
        debugPrint('Fetch responses timeout: $e');
      }
    } on SocketException catch (e) {
      _errorMessage = 'Network error. Please check your internet connection and ensure the server is running.';
      if (kDebugMode) {
        debugPrint('Fetch responses network error: $e');
      }
    } catch (e) {
      _errorMessage = 'Failed to load responses: ${e.toString()}';
      if (kDebugMode) {
        debugPrint('Fetch responses error: $e');
      }
    } finally {
      _isLoading = false;
      _isFetchingResponses = false;
      notifyListeners();
    }
  }
}

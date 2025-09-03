import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../services/http_service.dart';
import '../services/token_service.dart';
import '../config/api_config.dart';
import '../models/company_history.dart';

class CompanyHistoryProvider with ChangeNotifier {
  CompanyHistory? _companyHistory;
  bool _isLoading = false;
  String? _errorMessage;
  String? _accessToken;

  CompanyHistory? get companyHistory => _companyHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CompanyHistoryProvider();

  void setAccessToken(String? token) {
    final changed = token != _accessToken;
    _accessToken = token;
    if (changed) notifyListeners();
  }

  Future<void> loadCompanyHistory({String? accessToken}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = accessToken ??
          _accessToken ??
          await TokenService.getValidAccessToken();
      if (token == null) {
        _errorMessage = 'Authentication required. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await HttpService.get(
        ApiConfig.companyHistory,
        accessToken: token,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (kDebugMode) {
          print(">> Company history data received: ${data.length} records");
        }

        if (data.isNotEmpty) {
          _companyHistory =
              CompanyHistory.fromJson(data.last as Map<String, dynamic>);
          if (kDebugMode) {
            print(">> Company history loaded successfully");
          }
        } else {
          if (kDebugMode) {
            print(">> No company history found, initializing empty history");
          }
          _initializeEmptyHistory();
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Authentication required. Please log in again.';
        if (kDebugMode) {
          print(">> Authentication error: ${response.body}");
        }
      } else {
        _errorMessage = 'Failed to load data (${response.statusCode})';
        if (kDebugMode) {
          print(">> Error response: ${response.body}");
        }
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print(">> API Exception in loadCompanyHistory: ${e.message}");
      }
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
      if (kDebugMode) {
        print(">> Exception in loadCompanyHistory: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveCompanyHistory(CompanyHistory history,
      {String? accessToken}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = accessToken ??
          _accessToken ??
          await TokenService.getValidAccessToken();
      if (token == null) {
        _errorMessage = 'Authentication required. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final jsonBody = history.toJson();

      bool isValidUuid(String value) {
        final uuidRegExp = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
        return uuidRegExp.hasMatch(value);
      }

      final bool isUpdating = history.id.isNotEmpty && isValidUuid(history.id);

      final response = isUpdating
          ? await HttpService.put(
              ApiConfig.buildUrlWithParams(
                  ApiConfig.companyHistoryById, {'id': history.id}),
              accessToken: token,
              body: jsonBody,
            )
          : await HttpService.post(
              ApiConfig.companyHistory,
              accessToken: token,
              body: jsonBody,
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _companyHistory = CompanyHistory.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        // Ensure we reflect the server state
        await loadCompanyHistory();
      } else {
        _errorMessage = 'Failed to save data (${response.statusCode})';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print(">> API Exception in saveCompanyHistory: ${e.message}");
      }
    } catch (e) {
      _errorMessage = 'Error saving data: $e';
      if (kDebugMode) {
        print(">> Exception in saveCompanyHistory: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void _initializeEmptyHistory() {
    _companyHistory = CompanyHistory(
      id: '',
      company: '', // Add company field
      companyName: '',
      industry: '',
      yearEstablished: 0,
      numberOfEmployees: 0,
      securityHistory: '',
      currentSecurity: '',
      lastUpdated: DateTime.now(),
      networkArchitecture: '',
      incidentId: '',
      incidentTitle: '',
      incidentDescription: '',
      incidentDate: DateTime.now(),
      incidentImpact: '',
      incidentResolution: '',
      incidentLessonsLearned: '',
      toolId: '',
      toolName: '',
      toolCategory: '',
      toolVendor: '',
      toolVersion: '',
      toolImplementationDate: DateTime.now(),
      toolPurpose: '',
      toolCoverage: '',
      toolIsActive: false,
      policyId: '',
      policyTitle: '',
      policyDescription: '',
      policyCreationDate: DateTime.now(),
      policyLastReviewDate: DateTime.now(),
      policyDocumentUrl: '',
      policyScope: '',
      policyOwner: '',
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> prepareDataForAIAnalysis() async {
    if (_companyHistory == null) {
      await loadCompanyHistory();
    }

    if (_companyHistory != null) {
      return _companyHistory!.toAIAnalysisFormat();
    }

    return {};
  }
}

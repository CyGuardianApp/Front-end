import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
// import 'auth_provider.dart';
import '../models/company_history.dart';

class CompanyHistoryProvider with ChangeNotifier {
  CompanyHistory? _companyHistory;
  bool _isLoading = false;
  String? _errorMessage;
  String? _accessToken;

  String get _baseUrl => AuthService.apiBaseUrl;

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
      final headers = <String, String>{'Content-Type': 'application/json'};
      final token = accessToken ?? _accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/company-history/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(">> Company history data received: ${data.length} records");

        if (data.isNotEmpty) {
          _companyHistory =
              CompanyHistory.fromJson(data.last as Map<String, dynamic>);
          print(">> Company history loaded successfully");
        } else {
          print(">> No company history found, initializing empty history");
          _initializeEmptyHistory();
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Authentication required. Please log in again.';
        print(">> Authentication error: ${response.body}");
      } else {
        _errorMessage = 'Failed to load data (${response.statusCode})';
        print(">> Error response: ${response.body}");
      }
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
      print(">> Exception in loadCompanyHistory: $e");
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
      final jsonBody = history.toJson();

      bool isValidUuid(String value) {
        final uuidRegExp = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
        return uuidRegExp.hasMatch(value);
      }

      final bool isUpdating = history.id.isNotEmpty && isValidUuid(history.id);
      final request = http.Request(
        isUpdating ? 'PUT' : 'POST',
        Uri.parse(isUpdating
            ? '$_baseUrl/company-history/${history.id}'
            : '$_baseUrl/company-history/'),
      );
      request.headers['Content-Type'] = 'application/json';
      final token = accessToken ?? _accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.body = jsonEncode(jsonBody);

      final streamedResponse = await request.send();
      final responseData = await http.Response.fromStream(streamedResponse);

      if (responseData.statusCode == 200 || responseData.statusCode == 201) {
        _companyHistory = CompanyHistory.fromJson(
            jsonDecode(responseData.body) as Map<String, dynamic>);
        // Ensure we reflect the server state
        await loadCompanyHistory();
      } else {
        _errorMessage = 'فشل الحفظ (${responseData.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'خطأ أثناء الحفظ: $e';
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

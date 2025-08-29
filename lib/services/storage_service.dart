import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _companyHistoryKey = 'company_history';
  static const String _questionnairePrefix = 'questionnaire_';
  static const String _reportPrefix = 'report_';

  Future<void> saveCompanyHistory(String history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_companyHistoryKey, history);
    } catch (e) {
      // In a real app, you would handle errors more gracefully
      print('Error saving company history: $e');
      rethrow;
    }
  }

  Future<String?> getCompanyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_companyHistoryKey);
    } catch (e) {
      print('Error getting company history: $e');
      return null;
    }
  }

  Future<void> saveQuestionnaire(Map<String, dynamic> questionnaire) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = questionnaire['id'] as String;
      final data = jsonEncode(questionnaire);
      await prefs.setString('$_questionnairePrefix$id', data);
    } catch (e) {
      print('Error saving questionnaire: $e');
      rethrow;
    }
  }

  Future<void> saveReport(String reportId, String pdfData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_reportPrefix$reportId', pdfData);
    } catch (e) {
      print('Error saving report: $e');
      // lib/services/storage_service.dart (continuation)
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getQuestionnaire(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_questionnairePrefix$id');
      if (data == null) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting questionnaire: $e');
      return null;
    }
  }

  Future<List<String>> getAllQuestionnaireIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_questionnairePrefix))
          .map((key) => key.substring(_questionnairePrefix.length))
          .toList();
    } catch (e) {
      print('Error getting questionnaire IDs: $e');
      return [];
    }
  }

  Future<String?> getReport(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_reportPrefix$reportId');
    } catch (e) {
      print('Error getting report: $e');
      return null;
    }
  }

  Future<List<String>> getAllReportIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_reportPrefix))
          .map((key) => key.substring(_reportPrefix.length))
          .toList();
    } catch (e) {
      print('Error getting report IDs: $e');
      return [];
    }
  }

  Future<void> deleteData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      print('Error deleting data: $e');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }
}

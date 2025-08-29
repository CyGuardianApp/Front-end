import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class AIReportProvider with ChangeNotifier {
  final AIService _aiService;
  final StorageService _storageService;

  AIReportProvider(this._aiService, this._storageService);

  Future<void> generateReport({
    required double riskValue,
    required List<String> recommendations,
    required double estimatedCost,
    required String departmentData,
  }) async {
    final report = await _aiService.generateReport(
      riskValue: riskValue,
      recommendations: recommendations,
      estimatedCost: estimatedCost,
      departmentData: departmentData,
    );
    await _storageService.saveReport(
        'report_${DateTime.now().millisecondsSinceEpoch}', report);
    notifyListeners();
  }
}

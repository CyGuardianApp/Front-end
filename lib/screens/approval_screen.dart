import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/risk_assessment_provider.dart';
import '../widgets/saudi_riyal_symbol.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  List<Map<String, dynamic>> _approvedReports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApprovedReports();
  }

  Future<void> _loadApprovedReports() async {
    setState(() => _isLoading = true);
    final riskProvider =
        Provider.of<RiskAssessmentProvider>(context, listen: false);
    final reports = await riskProvider.loadApprovedReports();
    setState(() {
      _approvedReports = reports;
      _isLoading = false;
    });
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final riskScore = report['riskScore'] ?? 0.0;
    final riskLevel = report['riskLevel'] ?? 'Unknown';
    final findings = report['findings'] ?? [];
    final totalCost = report['totalRemedationCost'] ?? 0.0;

    Color riskColor;
    if (riskScore < 30) {
      riskColor = Colors.green;
    } else if (riskScore < 70) {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [riskColor, riskColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approved Risk Assessment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Approved: ${DateTime.parse(report['createdAt']).toLocal().toString().split('.')[0]}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Approved',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Risk Score
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    riskColor.withOpacity(0.1),
                    riskColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Risk Score',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        riskScore.toStringAsFixed(1),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: riskColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: riskColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      riskLevel,
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    Icons.report_problem,
                    'Findings',
                    findings.length.toString(),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    Icons.attach_money,
                    'Est. Cost',
                    totalCost.toStringAsFixed(0),
                    Colors.green,
                    useSaudiRiyal: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool useSaudiRiyal = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          useSaudiRiyal
              ? SaudiRiyalSymbol(amount: value, size: 20, color: color)
              : Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Risk Assessments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApprovedReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _approvedReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No approved reports',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Approved risk assessments will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _approvedReports.length,
                  itemBuilder: (context, index) {
                    return _buildReportCard(_approvedReports[index]);
                  },
                ),
    );
  }
}

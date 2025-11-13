import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/risk_assessment_provider.dart';
import '../widgets/saudi_riyal_symbol.dart';
import 'dashboard_screen.dart';

class AIReportScreen extends StatefulWidget {
  const AIReportScreen({super.key});

  @override
  State<AIReportScreen> createState() => _AIReportScreenState();
}

class _AIReportScreenState extends State<AIReportScreen> {
  List<Map<String, dynamic>> _pendingReports = [];
  Map<String, dynamic>? _selectedReport;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingReports();
  }

  Future<void> _loadPendingReports() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final riskProvider =
          Provider.of<RiskAssessmentProvider>(context, listen: false);
      final reports = await riskProvider.loadPendingReports();

      if (!mounted) return;

      // Store the current selected report ID to try to maintain selection
      final currentReportId = _selectedReport?['id'];

      setState(() {
        _pendingReports = reports;
        _isLoading = false;

        // If we have reports, ensure _selectedReport is valid
        if (reports.isNotEmpty) {
          // Try to find the previously selected report in the new list
          if (currentReportId != null) {
            final foundReport = reports.firstWhere(
              (report) => report['id'] == currentReportId,
              orElse: () => reports.first,
            );
            _selectedReport = foundReport;
          } else {
            // No previous selection, use the first report
            _selectedReport = reports.first;
          }
        } else {
          // No reports available
          _selectedReport = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _pendingReports = [];
        _selectedReport = null;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveReport(String reportId, bool approved) async {
    final riskProvider =
        Provider.of<RiskAssessmentProvider>(context, listen: false);
    final success =
        await riskProvider.approveRiskAssessment(reportId, approved);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved
                ? 'Risk assessment approved successfully!'
                : 'Risk assessment rejected.'),
            backgroundColor: approved ? Colors.green : Colors.orange,
          ),
        );
        // Reload pending reports
        await _loadPendingReports();
        // If approved, navigate to dashboard
        if (approved) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(riskProvider.errorMessage ?? 'Failed to process approval'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                        'AI Risk Assessment Report',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _formatDate(report['createdAt']),
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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Pending Approval',
                    style: TextStyle(
                      color: Colors.orange,
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
            const SizedBox(height: 24),

            // Findings List
            if (findings.isNotEmpty) ...[
              Text(
                'Security Findings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...findings.map((finding) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.security,
                          color: _getSeverityColor(finding['severity']),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                finding['description'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          _getSeverityColor(finding['severity'])
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      finding['severity'] ?? 'Unknown',
                                      style: TextStyle(
                                        color: _getSeverityColor(
                                            finding['severity']),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  SaudiRiyalSymbol(
                                    amount: (finding['estimatedCost'] as num?)
                                            ?.toStringAsFixed(0) ??
                                        '0',
                                    size: 14,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _approveReport(report['id'], false),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveReport(report['id'], true),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) return 'Unknown date';
      final date = dateValue is String
          ? DateTime.parse(dateValue)
          : dateValue as DateTime;
      return date.toLocal().toString().split('.')[0];
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskProvider = Provider.of<RiskAssessmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Risk Assessment Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingReports,
          ),
        ],
      ),
      body: _isLoading || riskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No pending AI reports',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate a risk assessment from a questionnaire response',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_pendingReports.length > 1) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedReport != null &&
                                    _pendingReports.any((r) =>
                                        r['id'] == _selectedReport!['id'])
                                ? _selectedReport
                                : (_pendingReports.isNotEmpty
                                    ? _pendingReports.first
                                    : null),
                            decoration: const InputDecoration(
                              labelText: 'Select Report',
                              border: OutlineInputBorder(),
                            ),
                            items: _pendingReports.asMap().entries.map((entry) {
                              final index = entry.key;
                              final report = entry.value;
                              return DropdownMenuItem(
                                value: report,
                                child: Text(
                                  'Report ${index + 1} - ${_formatDate(report['createdAt'])}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedReport = value);
                            },
                          ),
                        ),
                      ],
                      if (_selectedReport != null)
                        _buildReportCard(_selectedReport!),
                    ],
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/risk_assessment_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/saudi_riyal_symbol.dart';
import '../models/user.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load AI report if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final riskProvider =
          Provider.of<RiskAssessmentProvider>(context, listen: false);
      if (riskProvider.aiReport == null) {
        riskProvider.generateAIReport();
      }
    });
  }

  Widget _buildOrganizationInfoCard(
      BuildContext context, AuthProvider authProvider) {
    final currentUser = authProvider.user;
    if (currentUser == null) return const SizedBox.shrink();

    final organization =
        authProvider.findOrganizationByDomain(currentUser.domain);
    if (organization == null) return const SizedBox.shrink();

    // Format domain to look like organization name (e.g., "example.com" -> "Example")
    String orgName = organization.domain.split('.').first;
    orgName = orgName[0].toUpperCase() + orgName.substring(1);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organization',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          orgName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Show CTO info to CS Head and Sub Dept Heads
              if ((currentUser.role == UserRole.cyberSecurityHead ||
                      currentUser.role == UserRole.subDepartmentHead) &&
                  organization.cto != null) ...[
                _buildInfoRow(
                  context,
                  Icons.person,
                  'CTO',
                  organization.cto!.name,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
              ],

              // Show CS Head info to CTO and Sub Dept Heads
              if ((currentUser.role == UserRole.cto ||
                      currentUser.role == UserRole.subDepartmentHead) &&
                  organization.cyberSecurityHead != null) ...[
                _buildInfoRow(
                  context,
                  Icons.security,
                  'Cybersecurity Head',
                  organization.cyberSecurityHead!.name,
                  Colors.green,
                ),
                const SizedBox(height: 12),
              ],

              // Show Department Name if Sub-Department Head
              if (currentUser.role == UserRole.subDepartmentHead &&
                  currentUser.departmentName != null) ...[
                _buildInfoRow(
                  context,
                  Icons.apartment,
                  'Department',
                  currentUser.departmentName!,
                  Colors.blueGrey,
                ),
                const SizedBox(height: 12),
              ],

              // Show sub-department count for all roles
              _buildInfoRow(
                context,
                Icons.people,
                'Sub-Departments',
                '${organization.subDepartmentHeads.length}',
                Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard(
      BuildContext context, Map<String, dynamic>? aiReport) {
    final riskScore = aiReport?['riskScore'] ?? 0;
    final riskLevel = aiReport?['riskLevel'] ?? 'Unknown';

    Color riskColor;
    if (riskScore < 30) {
      riskColor = Colors.green;
    } else if (riskScore < 70) {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            riskColor.withOpacity(0.1),
            riskColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: riskColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              riskColor,
                              riskColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Overall Risk Score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      border: Border.all(
                        color: riskColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      riskLevel,
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            riskColor,
                            riskColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: riskScore / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    riskScore.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '100',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, Map<String, dynamic>? aiReport) {
    final totalFindings = aiReport?['findings']?.length ?? 0;
    final highSeverityCount =
        aiReport?['findings']?.where((f) => f['severity'] == 'High').length ??
            0;
    final totalCost = aiReport?['totalRemedationCost'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            Icons.report_problem,
            'Total Findings',
            totalFindings.toString(),
            Colors.orange,
            'Security issues found',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            Icons.warning,
            'High Severity',
            highSeverityCount.toString(),
            Colors.red,
            'Critical issues',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            Icons.attach_money,
            'Est. Cost',
            totalCost.toString(),
            Colors.green,
            'Remediation cost',
            useSaudiRiyal: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, IconData icon, String title,
      String value, Color color, String subtitle,
      {bool useSaudiRiyal = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              useSaudiRiyal
                  ? SaudiRiyalSymbol(
                      amount: value,
                      size: 32,
                      color: color,
                    )
                  : Text(
                      value,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCISOManagementCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/sub-department-management');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Sub-Department Heads',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Create and manage accounts for sub-department heads',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'New sub-department heads will be required to change their password on first login for security.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFindingsTable(
      BuildContext context, Map<String, dynamic>? aiReport) {
    final findings = aiReport?['findings'] ?? [];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.purple.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Top Security Findings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (findings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No findings available',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                      dataTextStyle: Theme.of(context).textTheme.bodyMedium,
                      columns: const [
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Severity')),
                        DataColumn(label: Text('Est. Cost')),
                      ],
                      rows: List<DataRow>.generate(
                        findings.length > 5 ? 5 : findings.length,
                        (index) => DataRow(
                          cells: [
                            DataCell(Text(findings[index]['category'] ?? '')),
                            DataCell(
                                Text(findings[index]['description'] ?? '')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: findings[index]['severity'] == 'High'
                                      ? Colors.red.withOpacity(0.1)
                                      : findings[index]['severity'] == 'Medium'
                                          ? Colors.orange.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: findings[index]['severity'] == 'High'
                                        ? Colors.red.withOpacity(0.3)
                                        : findings[index]['severity'] ==
                                                'Medium'
                                            ? Colors.orange.withOpacity(0.3)
                                            : Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  findings[index]['severity'] ?? '',
                                  style: TextStyle(
                                    color: findings[index]['severity'] == 'High'
                                        ? Colors.red
                                        : findings[index]['severity'] ==
                                                'Medium'
                                            ? Colors.orange
                                            : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(SaudiRiyalSymbol(
                              amount:
                                  '${findings[index]['estimatedCost'] ?? 0}',
                              size: 16,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (findings.length > 5) ...[
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/ai-report');
                      },
                      icon: const Icon(Icons.visibility, color: Colors.white),
                      label: const Text(
                        'View All Findings',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final riskProvider = Provider.of<RiskAssessmentProvider>(context);
    final aiReport = riskProvider.aiReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                riskProvider.generateAIReport();
              },
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: riskProvider.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome message
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.user?.name ?? 'User',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Here\'s your cybersecurity overview',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Organization info card
                      _buildOrganizationInfoCard(context, authProvider),
                      const SizedBox(height: 24),

                      // Risk score card
                      _buildRiskScoreCard(context, aiReport),
                      const SizedBox(height: 24),

                      // Summary cards
                      _buildSummaryCards(context, aiReport),
                      const SizedBox(height: 24),

                      if (authProvider.user?.role ==
                          UserRole.cyberSecurityHead) ...[
                        _buildCISOManagementCard(context),
                        const SizedBox(height: 24),
                      ],

                      // Findings table
                      _buildFindingsTable(context, aiReport),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

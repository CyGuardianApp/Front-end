import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/company_history_provider.dart';
import '../models/company_history.dart';
import '../widgets/app_drawer.dart';

class CompanyHistoryScreen extends StatefulWidget {
  const CompanyHistoryScreen({super.key});

  @override
  _CompanyHistoryScreenState createState() => _CompanyHistoryScreenState();
}

class _CompanyHistoryScreenState extends State<CompanyHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  // الحقول الرئيسية للشركة
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();
  final _yearEstablishedController = TextEditingController();
  final _employeeCountController = TextEditingController();
  final _securityHistoryController = TextEditingController();
  final _currentSecurityController = TextEditingController();
  final _networkDescriptionController = TextEditingController();

  // حقول الحادث الأمني
  final _incidentTitleController = TextEditingController();
  final _incidentDescriptionController = TextEditingController();
  final _incidentImpactController = TextEditingController();
  final _incidentResolutionController = TextEditingController();
  final _incidentLessonsController = TextEditingController();
  DateTime _incidentDate = DateTime.now();

  // حقول الأداة الأمنية
  final _toolNameController = TextEditingController();
  final _toolCategoryController = TextEditingController();
  final _toolVendorController = TextEditingController();
  final _toolVersionController = TextEditingController();
  final _toolPurposeController = TextEditingController();
  final _toolCoverageController = TextEditingController();
  DateTime _toolImplementationDate = DateTime.now();
  bool _toolIsActive = true;

  // حقول وثيقة السياسة
  final _policyTitleController = TextEditingController();
  final _policyDescriptionController = TextEditingController();
  final _policyUrlController = TextEditingController();
  final _policyScopeController = TextEditingController();
  final _policyOwnerController = TextEditingController();
  DateTime _policyCreationDate = DateTime.now();
  DateTime _policyReviewDate = DateTime.now();

  bool _isEditing = false;
  final bool _isLoading = false;

  // Multiple entries state
  final List<Map<String, dynamic>> _incidents = [];
  final List<Map<String, dynamic>> _tools = [];
  final List<Map<String, dynamic>> _policies = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyProvider =
          Provider.of<CompanyHistoryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      historyProvider
          .loadCompanyHistory(accessToken: authProvider.accessToken ?? '')
          .then((_) {
        if (historyProvider.companyHistory != null) {
          _loadCompanyHistory();
        }
      });
    });
  }

  @override
  void dispose() {
    // التخلص من جميع المتحكمات
    _companyNameController.dispose();
    _industryController.dispose();
    _yearEstablishedController.dispose();
    _employeeCountController.dispose();
    _securityHistoryController.dispose();
    _currentSecurityController.dispose();
    _networkDescriptionController.dispose();

    _incidentTitleController.dispose();
    _incidentDescriptionController.dispose();
    _incidentImpactController.dispose();
    _incidentResolutionController.dispose();
    _incidentLessonsController.dispose();

    _toolNameController.dispose();
    _toolCategoryController.dispose();
    _toolVendorController.dispose();
    _toolVersionController.dispose();
    _toolPurposeController.dispose();
    _toolCoverageController.dispose();

    _policyTitleController.dispose();
    _policyDescriptionController.dispose();
    _policyUrlController.dispose();
    _policyScopeController.dispose();
    _policyOwnerController.dispose();

    super.dispose();
  }

  void _loadCompanyHistory() async {
    try {
      final historyProvider =
          Provider.of<CompanyHistoryProvider>(context, listen: false);
      final companyHistory = historyProvider.companyHistory;

      if (companyHistory != null) {
        setState(() {
          // تعبئة جميع الحقول
          _companyNameController.text = companyHistory.companyName;
          _industryController.text = companyHistory.industry;
          _yearEstablishedController.text =
              companyHistory.yearEstablished.toString();
          _employeeCountController.text =
              companyHistory.numberOfEmployees.toString();
          _securityHistoryController.text = companyHistory.securityHistory;
          _currentSecurityController.text = companyHistory.currentSecurity;
          _networkDescriptionController.text =
              companyHistory.networkArchitecture;

          // حقول الحادث الأمني
          _incidentTitleController.text = companyHistory.incidentTitle;
          _incidentDescriptionController.text =
              companyHistory.incidentDescription;
          _incidentDate = companyHistory.incidentDate;
          _incidentImpactController.text = companyHistory.incidentImpact;
          _incidentResolutionController.text =
              companyHistory.incidentResolution;
          _incidentLessonsController.text =
              companyHistory.incidentLessonsLearned;

          // حقول الأداة الأمنية
          _toolNameController.text = companyHistory.toolName;
          _toolCategoryController.text = companyHistory.toolCategory;
          _toolVendorController.text = companyHistory.toolVendor;
          _toolVersionController.text = companyHistory.toolVersion;
          _toolImplementationDate = companyHistory.toolImplementationDate;
          _toolPurposeController.text = companyHistory.toolPurpose;
          _toolCoverageController.text = companyHistory.toolCoverage;
          _toolIsActive = companyHistory.toolIsActive;

          // حقول وثيقة السياسة
          _policyTitleController.text = companyHistory.policyTitle;
          _policyDescriptionController.text = companyHistory.policyDescription;
          _policyCreationDate = companyHistory.policyCreationDate;
          _policyReviewDate = companyHistory.policyLastReviewDate;
          _policyUrlController.text = companyHistory.policyDocumentUrl;
          _policyScopeController.text = companyHistory.policyScope;
          _policyOwnerController.text = companyHistory.policyOwner;

          // Load arrays if present
          _incidents
            ..clear()
            ..addAll(companyHistory.incidents);
          _tools
            ..clear()
            ..addAll(companyHistory.tools);
          _policies
            ..clear()
            ..addAll(companyHistory.policies);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading company history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCompanyHistory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final historyProvider =
          Provider.of<CompanyHistoryProvider>(context, listen: false);
      final currentHistory = historyProvider.companyHistory;

      // Use server-generated UUIDs; send empty id if creating new
      String id = currentHistory?.id ?? '';
      String incidentId = currentHistory?.incidentId.isNotEmpty == true
          ? currentHistory!.incidentId
          : '';
      String toolId = currentHistory?.toolId.isNotEmpty == true
          ? currentHistory!.toolId
          : '';
      String policyId = currentHistory?.policyId.isNotEmpty == true
          ? currentHistory!.policyId
          : '';

      // إنشاء كائن CompanyHistory محدث
      final updatedHistory = CompanyHistory(
        id: id,
        company: currentHistory?.company ?? '', // Add company field
        companyName: _companyNameController.text,
        industry: _industryController.text,
        yearEstablished: int.tryParse(_yearEstablishedController.text) ?? 0,
        numberOfEmployees: int.tryParse(_employeeCountController.text) ?? 0,
        securityHistory: _securityHistoryController.text,
        currentSecurity: _currentSecurityController.text,
        networkArchitecture: _networkDescriptionController.text,
        lastUpdated: DateTime.now(),

        // حقول الحادث الأمني
        incidentId: incidentId,
        incidentTitle: _incidentTitleController.text,
        incidentDescription: _incidentDescriptionController.text,
        incidentDate: _incidentDate,
        incidentImpact: _incidentImpactController.text,
        incidentResolution: _incidentResolutionController.text,
        incidentLessonsLearned: _incidentLessonsController.text,

        // حقول الأداة الأمنية
        toolId: toolId,
        toolName: _toolNameController.text,
        toolCategory: _toolCategoryController.text,
        toolVendor: _toolVendorController.text,
        toolVersion: _toolVersionController.text,
        toolImplementationDate: _toolImplementationDate,
        toolPurpose: _toolPurposeController.text,
        toolCoverage: _toolCoverageController.text,
        toolIsActive: _toolIsActive,

        // حقول وثيقة السياسة
        policyId: policyId,
        policyTitle: _policyTitleController.text,
        policyDescription: _policyDescriptionController.text,
        policyCreationDate: _policyCreationDate,
        policyLastReviewDate: _policyReviewDate,
        policyDocumentUrl: _policyUrlController.text,
        policyScope: _policyScopeController.text,
        policyOwner: _policyOwnerController.text,
        incidents: _incidents,
        tools: _tools,
        policies: _policies,
      );

      // حفظ في قاعدة البيانات
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await historyProvider.saveCompanyHistory(updatedHistory,
          accessToken: authProvider.accessToken ?? '');

      // تحديث واجهة المستخدم
      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company information saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = Provider.of<CompanyHistoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Allow any authenticated user to edit company history for now
    // TODO: Update this based on your actual role names
    final isCSHead = user != null;
    final companyHistory = historyProvider.companyHistory;
    final lastUpdated = (companyHistory != null)
        ? '${companyHistory.lastUpdated.day}/${companyHistory.lastUpdated.month}/${companyHistory.lastUpdated.year}'
        : 'Never';

    if (historyProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Company History'),
        ),
        drawer: const AppDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (historyProvider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Company History'),
        ),
        drawer: const AppDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${historyProvider.errorMessage}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  historyProvider.loadCompanyHistory();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company History'),
        actions: [
          if (isCSHead)
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
              child: Text(
                _isEditing ? 'Cancel' : 'Edit',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isEditing
            ? _buildEditForm()
            : _buildDisplayView(companyHistory, lastUpdated),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This information helps the AI model understand your organization\'s context',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The security practices and infrastructure details you provide will be used to generate more accurate risk assessments and recommendations.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Organization Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Organization Details',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    hintText: 'Enter your company name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your company name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _industryController,
                  decoration: const InputDecoration(
                    labelText: 'Industry',
                    hintText: 'E.g., Manufacturing, Finance, Healthcare',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your industry'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearEstablishedController,
                        decoration: const InputDecoration(
                          labelText: 'Year Established',
                          hintText: 'E.g., 2005',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter year';
                          }
                          final year = int.tryParse(value);
                          if (year == null ||
                              year < 1900 ||
                              year > DateTime.now().year) {
                            return 'Enter valid year';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _employeeCountController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Employees',
                          hintText: 'E.g., 500',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter count';
                          }
                          final count = int.tryParse(value);
                          if (count == null || count <= 0) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security History and Infrastructure
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2. Security History and Infrastructure',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _securityHistoryController,
                  decoration: const InputDecoration(
                    labelText: 'Security History',
                    hintText: 'Describe your organization\'s security history',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter security history'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentSecurityController,
                  decoration: const InputDecoration(
                    labelText: 'Current Security Measures',
                    hintText: 'Describe your current security measures',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter current security measures'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _networkDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Network Architecture Description',
                    hintText: 'Describe your network architecture',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter network description'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security Incident
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3. Security Incident',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                // Existing single-entry editors (can seed a new incident)
                TextFormField(
                  controller: _incidentTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Incident Title',
                    hintText: 'Enter the title of the security incident',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _incidentDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe what happened during the incident',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _incidentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _incidentDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Incident Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_incidentDate.toLocal().toString().split(' ')[0]),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _incidentImpactController,
                  decoration: const InputDecoration(
                    labelText: 'Impact',
                    hintText: 'Describe the impact on your organization',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _incidentResolutionController,
                  decoration: const InputDecoration(
                    labelText: 'Resolution',
                    hintText: 'How was the incident resolved?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _incidentLessonsController,
                  decoration: const InputDecoration(
                    labelText: 'Lessons Learned',
                    hintText:
                        'What did your organization learn from this incident?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final entry = {
                          'incident_id':
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          'incident_title': _incidentTitleController.text,
                          'incident_description':
                              _incidentDescriptionController.text,
                          'incident_date': _incidentDate.toIso8601String(),
                          'incident_impact': _incidentImpactController.text,
                          'incident_resolution':
                              _incidentResolutionController.text,
                          'incident_lessons_learned':
                              _incidentLessonsController.text,
                        };
                        setState(() {
                          _incidents.add(entry);
                          _incidentTitleController.clear();
                          _incidentDescriptionController.clear();
                          _incidentImpactController.clear();
                          _incidentResolutionController.clear();
                          _incidentLessonsController.clear();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Incident'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_incidents.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Incidents (${_incidents.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._incidents.asMap().entries.map((e) {
                        final idx = e.key;
                        final it = e.value;
                        return Card(
                          child: ListTile(
                            title: Text(it['incident_title'] ?? ''),
                            subtitle: Text(it['incident_description'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _incidents.removeAt(idx));
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security Tool
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('4. Security Tool',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                // Single-entry editors to seed a new tool
                TextFormField(
                  controller: _toolNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tool Name',
                    hintText: 'Enter the name of the security tool',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toolCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'E.g., Firewall, Antivirus, IDS, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _toolVendorController,
                        decoration: const InputDecoration(
                          labelText: 'Vendor',
                          hintText: 'Tool vendor name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _toolVersionController,
                        decoration: const InputDecoration(
                          labelText: 'Version',
                          hintText: 'Tool version',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _toolImplementationDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _toolImplementationDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Implementation Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_toolImplementationDate
                            .toLocal()
                            .toString()
                            .split(' ')[0]),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toolPurposeController,
                  decoration: const InputDecoration(
                    labelText: 'Purpose',
                    hintText: 'What security purposes does this tool serve?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toolCoverageController,
                  decoration: const InputDecoration(
                    labelText: 'Coverage',
                    hintText: 'Which systems/assets are covered by this tool?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Tool is Currently Active'),
                  value: _toolIsActive,
                  onChanged: (value) => setState(() => _toolIsActive = value),
                  activeColor: Theme.of(context).primaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final entry = {
                          'tool_id':
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          'tool_name': _toolNameController.text,
                          'tool_category': _toolCategoryController.text,
                          'tool_vendor': _toolVendorController.text,
                          'tool_version': _toolVersionController.text,
                          'tool_implementation_date':
                              _toolImplementationDate.toIso8601String(),
                          'tool_purpose': _toolPurposeController.text,
                          'tool_coverage': _toolCoverageController.text,
                          'tool_is_active': _toolIsActive,
                        };
                        setState(() {
                          _tools.add(entry);
                          _toolNameController.clear();
                          _toolCategoryController.clear();
                          _toolVendorController.clear();
                          _toolVersionController.clear();
                          _toolPurposeController.clear();
                          _toolCoverageController.clear();
                          _toolIsActive = true;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Tool'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_tools.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tools (${_tools.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._tools.asMap().entries.map((e) {
                        final idx = e.key;
                        final it = e.value;
                        return Card(
                          child: ListTile(
                            title: Text(it['tool_name'] ?? ''),
                            subtitle: Text(it['tool_vendor'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _tools.removeAt(idx));
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Policy Document
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('5. Policy Document',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                // Single-entry editors to seed a new policy
                TextFormField(
                  controller: _policyTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Policy Title',
                    hintText: 'Enter the title of the policy document',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _policyDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the purpose and content of this policy',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _policyCreationDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _policyCreationDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Creation Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_policyCreationDate
                            .toLocal()
                            .toString()
                            .split(' ')[0]),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _policyReviewDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _policyReviewDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Last Review Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_policyReviewDate
                            .toLocal()
                            .toString()
                            .split(' ')[0]),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _policyUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Document URL',
                    hintText: 'Link to the policy document',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _policyScopeController,
                  decoration: const InputDecoration(
                    labelText: 'Scope',
                    hintText:
                        'Which departments/systems does this policy apply to?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _policyOwnerController,
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    hintText: 'Who is responsible for this policy?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final entry = {
                          'policy_id':
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          'policy_title': _policyTitleController.text,
                          'policy_description':
                              _policyDescriptionController.text,
                          'policy_creation_date':
                              _policyCreationDate.toIso8601String(),
                          'policy_last_review_date':
                              _policyReviewDate.toIso8601String(),
                          'policy_document_url': _policyUrlController.text,
                          'policy_scope': _policyScopeController.text,
                          'policy_owner': _policyOwnerController.text,
                        };
                        setState(() {
                          _policies.add(entry);
                          _policyTitleController.clear();
                          _policyDescriptionController.clear();
                          _policyUrlController.clear();
                          _policyScopeController.clear();
                          _policyOwnerController.clear();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Policy'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_policies.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Policies (${_policies.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._policies.asMap().entries.map((e) {
                        final idx = e.key;
                        final it = e.value;
                        return Card(
                          child: ListTile(
                            title: Text(it['policy_title'] ?? ''),
                            subtitle: Text(it['policy_document_url'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _policies.removeAt(idx));
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          Center(
            child: ElevatedButton.icon(
              onPressed: _saveCompanyHistory,
              icon: const Icon(Icons.save),
              label: const Text('Save Company Information'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDisplayView(CompanyHistory? companyHistory, String lastUpdated) {
    // If no company history or empty values, show the empty state
    final hasData = companyHistory != null &&
        ((companyHistory.companyName.isNotEmpty) ||
            (companyHistory.industry.isNotEmpty) ||
            (companyHistory.securityHistory.isNotEmpty) ||
            (companyHistory.currentSecurity.isNotEmpty));

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No company profile found. Please add your organization\'s information.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Company Information'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A76C9),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Last updated info
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Last updated: $lastUpdated',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 1. معلومات الشركة
        _buildSectionCard(
          context: context,
          title: 'Organization Details',
          color: Colors.blue.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyHistory.companyName ?? 'Unknown Company',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.category,
                'Industry',
                companyHistory.industry ?? 'Unknown',
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Established',
                (companyHistory.yearEstablished ?? 'Unknown').toString(),
              ),
              _buildInfoRow(
                Icons.people,
                'Employees',
                (companyHistory.numberOfEmployees ?? 'Unknown').toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. تاريخ الأمان والبنية التحتية
        _buildSectionCard(
          context: context,
          title: 'Security History and Infrastructure',
          color: Colors.teal.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubtitle(context, 'Security History'),
              Text(
                companyHistory.securityHistory ??
                    'No security history available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _buildSubtitle(context, 'Current Security Measures'),
              Text(
                companyHistory.currentSecurity ??
                    'No current security information available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _buildSubtitle(context, 'Network Architecture'),
              Text(
                companyHistory.networkArchitecture ??
                    'No network architecture information available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. معلومات الحادث الأمني (إذا كانت متوفرة)
        if (companyHistory.incidentTitle.isNotEmpty == true)
          _buildSectionCard(
            context: context,
            title: 'Security Incident',
            color: Colors.red.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyHistory.incidentTitle ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Date',
                  companyHistory.incidentDate != null
                      ? '${companyHistory.incidentDate.day}/${companyHistory.incidentDate.month}/${companyHistory.incidentDate.year}'
                      : 'Unknown',
                ),
                const SizedBox(height: 8),
                _buildSubtitle(context, 'Description'),
                Text(
                  companyHistory.incidentDescription ??
                      'No description available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _buildSubtitle(context, 'Impact'),
                Text(
                  companyHistory.incidentImpact ??
                      'No impact information available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _buildSubtitle(context, 'Resolution'),
                Text(
                  companyHistory.incidentResolution ??
                      'No resolution information available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _buildSubtitle(context, 'Lessons Learned'),
                Text(
                  companyHistory.incidentLessonsLearned ??
                      'No lessons learned information available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        if (companyHistory.incidentTitle.isNotEmpty == true)
          const SizedBox(height: 16),

        // 3.b عرض قائمة الحوادث الأمنية المتعددة إن وُجدت
        if ((companyHistory.incidents.isNotEmpty ?? false))
          _buildSectionCard(
            context: context,
            title: 'Security Incidents',
            color: Colors.red.withOpacity(0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...companyHistory.incidents.map((it) {
                  final String title = (it['incident_title'] ?? '').toString();
                  final String description =
                      (it['incident_description'] ?? '').toString();
                  final String impact =
                      (it['incident_impact'] ?? '').toString();
                  final String resolution =
                      (it['incident_resolution'] ?? '').toString();
                  final String lessons =
                      (it['incident_lessons_learned'] ?? '').toString();
                  final String dateStr = (it['incident_date'] ?? '').toString();
                  DateTime? date;
                  try {
                    date = DateTime.tryParse(dateStr);
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isNotEmpty ? title : 'Untitled Incident',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Date',
                              date != null
                                  ? '${date.day}/${date.month}/${date.year}'
                                  : (dateStr.isNotEmpty ? dateStr : 'Unknown'),
                            ),
                            const SizedBox(height: 8),
                            _buildSubtitle(context, 'Description'),
                            Text(
                              description.isNotEmpty
                                  ? description
                                  : 'No description available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildSubtitle(context, 'Impact'),
                            Text(
                              impact.isNotEmpty
                                  ? impact
                                  : 'No impact information available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildSubtitle(context, 'Resolution'),
                            Text(
                              resolution.isNotEmpty
                                  ? resolution
                                  : 'No resolution information available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildSubtitle(context, 'Lessons Learned'),
                            Text(
                              lessons.isNotEmpty
                                  ? lessons
                                  : 'No lessons learned information available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        if ((companyHistory.incidents.isNotEmpty ?? false))
          const SizedBox(height: 16),

        // 4. معلومات الأداة الأمنية (إذا كانت متوفرة)
        if (companyHistory.toolName.isNotEmpty == true)
          _buildSectionCard(
            context: context,
            title: 'Security Tool',
            color: Colors.green.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyHistory.toolName ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.category,
                  'Category',
                  companyHistory.toolCategory ?? 'Unknown',
                ),
                _buildInfoRow(
                  Icons.business,
                  'Vendor',
                  companyHistory.toolVendor ?? 'Unknown',
                ),
                _buildInfoRow(
                  Icons.numbers,
                  'Version',
                  companyHistory.toolVersion ?? 'Unknown',
                ),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Implementation Date',
                  companyHistory.toolImplementationDate != null
                      ? '${companyHistory.toolImplementationDate.day}/${companyHistory.toolImplementationDate.month}/${companyHistory.toolImplementationDate.year}'
                      : 'Unknown',
                ),
                _buildInfoRow(
                  Icons.check_circle,
                  'Active',
                  companyHistory.toolIsActive == true ? 'Yes' : 'No',
                ),
                const SizedBox(height: 8),
                _buildSubtitle(context, 'Purpose'),
                Text(
                  companyHistory.toolPurpose ??
                      'No purpose information available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _buildSubtitle(context, 'Coverage'),
                Text(
                  companyHistory.toolCoverage ??
                      'No coverage information available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        if (companyHistory.toolName.isNotEmpty == true)
          const SizedBox(height: 16),

        // 4.b عرض قائمة الأدوات الأمنية المتعددة إن وُجدت
        if ((companyHistory.tools.isNotEmpty ?? false))
          _buildSectionCard(
            context: context,
            title: 'Security Tools',
            color: Colors.green.withOpacity(0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...companyHistory.tools.map((it) {
                  final String name = (it['tool_name'] ?? '').toString();
                  final String category =
                      (it['tool_category'] ?? '').toString();
                  final String vendor = (it['tool_vendor'] ?? '').toString();
                  final String version = (it['tool_version'] ?? '').toString();
                  final String purpose = (it['tool_purpose'] ?? '').toString();
                  final String coverage =
                      (it['tool_coverage'] ?? '').toString();
                  final dynamic activeRaw = it['tool_is_active'];
                  final bool isActive = activeRaw is bool
                      ? activeRaw
                      : (activeRaw?.toString().toLowerCase() == 'true');
                  final String dateStr =
                      (it['tool_implementation_date'] ?? '').toString();
                  DateTime? date;
                  try {
                    date = DateTime.tryParse(dateStr);
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : 'Unnamed Tool',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.category,
                              'Category',
                              category.isNotEmpty ? category : 'Unknown',
                            ),
                            _buildInfoRow(
                              Icons.business,
                              'Vendor',
                              vendor.isNotEmpty ? vendor : 'Unknown',
                            ),
                            _buildInfoRow(
                              Icons.numbers,
                              'Version',
                              version.isNotEmpty ? version : 'Unknown',
                            ),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Implementation Date',
                              date != null
                                  ? '${date.day}/${date.month}/${date.year}'
                                  : (dateStr.isNotEmpty ? dateStr : 'Unknown'),
                            ),
                            _buildInfoRow(
                              Icons.check_circle,
                              'Active',
                              isActive ? 'Yes' : 'No',
                            ),
                            const SizedBox(height: 8),
                            _buildSubtitle(context, 'Purpose'),
                            Text(
                              purpose.isNotEmpty
                                  ? purpose
                                  : 'No purpose information available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildSubtitle(context, 'Coverage'),
                            Text(
                              coverage.isNotEmpty
                                  ? coverage
                                  : 'No coverage information available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        if ((companyHistory.tools.isNotEmpty ?? false))
          const SizedBox(height: 16),

        // 5. معلومات وثيقة السياسة (إذا كانت متوفرة)
        if (companyHistory.policyTitle.isNotEmpty == true)
          _buildSectionCard(
            context: context,
            title: 'Policy Document',
            color: Colors.amber.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyHistory.policyTitle ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Creation Date',
                  companyHistory.policyCreationDate != null
                      ? '${companyHistory.policyCreationDate.day}/${companyHistory.policyCreationDate.month}/${companyHistory.policyCreationDate.year}'
                      : 'Unknown',
                ),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Last Review Date',
                  companyHistory.policyLastReviewDate != null
                      ? '${companyHistory.policyLastReviewDate.day}/${companyHistory.policyLastReviewDate.month}/${companyHistory.policyLastReviewDate.year}'
                      : 'Unknown',
                ),
                if (companyHistory.policyDocumentUrl.isNotEmpty == true)
                  _buildInfoRow(
                    Icons.link,
                    'Document URL',
                    companyHistory.policyDocumentUrl ?? 'No URL available',
                  ),
                _buildInfoRow(
                  Icons.domain,
                  'Scope',
                  companyHistory.policyScope ?? 'Unknown',
                ),
                _buildInfoRow(
                  Icons.person,
                  'Owner',
                  companyHistory.policyOwner ?? 'Unknown',
                ),
                const SizedBox(height: 8),
                _buildSubtitle(context, 'Description'),
                Text(
                  companyHistory.policyDescription ??
                      'No description available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        if (companyHistory.policyTitle.isNotEmpty == true)
          const SizedBox(height: 16),

        // 5.b عرض قائمة وثائق السياسات المتعددة إن وُجدت
        if ((companyHistory.policies.isNotEmpty ?? false))
          _buildSectionCard(
            context: context,
            title: 'Policy Documents',
            color: Colors.amber.withOpacity(0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...companyHistory.policies.map((it) {
                  final String title = (it['policy_title'] ?? '').toString();
                  final String description =
                      (it['policy_description'] ?? '').toString();
                  final String url =
                      (it['policy_document_url'] ?? '').toString();
                  final String scope = (it['policy_scope'] ?? '').toString();
                  final String owner = (it['policy_owner'] ?? '').toString();
                  final String createdStr =
                      (it['policy_creation_date'] ?? '').toString();
                  final String reviewStr =
                      (it['policy_last_review_date'] ?? '').toString();
                  DateTime? created;
                  DateTime? review;
                  try {
                    created = DateTime.tryParse(createdStr);
                  } catch (_) {}
                  try {
                    review = DateTime.tryParse(reviewStr);
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isNotEmpty ? title : 'Untitled Policy',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Creation Date',
                              created != null
                                  ? '${created.day}/${created.month}/${created.year}'
                                  : (createdStr.isNotEmpty
                                      ? createdStr
                                      : 'Unknown'),
                            ),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Last Review Date',
                              review != null
                                  ? '${review.day}/${review.month}/${review.year}'
                                  : (reviewStr.isNotEmpty
                                      ? reviewStr
                                      : 'Unknown'),
                            ),
                            if (url.isNotEmpty)
                              _buildInfoRow(
                                Icons.link,
                                'Document URL',
                                url,
                              ),
                            _buildInfoRow(
                              Icons.domain,
                              'Scope',
                              scope.isNotEmpty ? scope : 'Unknown',
                            ),
                            _buildInfoRow(
                              Icons.person,
                              'Owner',
                              owner.isNotEmpty ? owner : 'Unknown',
                            ),
                            const SizedBox(height: 8),
                            _buildSubtitle(context, 'Description'),
                            Text(
                              description.isNotEmpty
                                  ? description
                                  : 'No description available',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        if ((companyHistory.policies.isNotEmpty ?? false))
          const SizedBox(height: 16),

        // بطاقة معلومات التحليل
        Card(
          elevation: 2,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'AI Analysis Insight',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This information is used by the AI to contextualize your organization\'s risk assessment. The more detailed and accurate your security history and current measures, the more tailored the recommendations will be.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your company profile influences risk scoring in areas such as industry-specific threats, organizational maturity, and historical vulnerability patterns.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

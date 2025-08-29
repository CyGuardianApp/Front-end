class CompanyHistory {
  final String id;
  final String company; // Add company field
  final String companyName;
  final String industry;
  final int yearEstablished;
  final int numberOfEmployees;
  final String securityHistory;
  final String currentSecurity;
  final DateTime lastUpdated;
  final String networkArchitecture;

  final String incidentId;
  final String incidentTitle;
  final String incidentDescription;
  final DateTime incidentDate;
  final String incidentImpact;
  final String incidentResolution;
  final String incidentLessonsLearned;

  final String toolId;
  final String toolName;
  final String toolCategory;
  final String toolVendor;
  final String toolVersion;
  final DateTime toolImplementationDate;
  final String toolPurpose;
  final String toolCoverage;
  final bool toolIsActive;

  final String policyId;
  final String policyTitle;
  final String policyDescription;
  final DateTime policyCreationDate;
  final DateTime policyLastReviewDate;
  final String policyDocumentUrl;
  final String policyScope;
  final String policyOwner;

  // New: support multiple entries (optional for now)
  final List<Map<String, dynamic>> incidents;
  final List<Map<String, dynamic>> tools;
  final List<Map<String, dynamic>> policies;

  CompanyHistory({
    required this.id,
    required this.company, // Add company field
    required this.companyName,
    required this.industry,
    required this.yearEstablished,
    required this.numberOfEmployees,
    required this.securityHistory,
    required this.currentSecurity,
    required this.lastUpdated,
    required this.networkArchitecture,
    required this.incidentId,
    required this.incidentTitle,
    required this.incidentDescription,
    required this.incidentDate,
    required this.incidentImpact,
    required this.incidentResolution,
    required this.incidentLessonsLearned,
    required this.toolId,
    required this.toolName,
    required this.toolCategory,
    required this.toolVendor,
    required this.toolVersion,
    required this.toolImplementationDate,
    required this.toolPurpose,
    required this.toolCoverage,
    required this.toolIsActive,
    required this.policyId,
    required this.policyTitle,
    required this.policyDescription,
    required this.policyCreationDate,
    required this.policyLastReviewDate,
    required this.policyDocumentUrl,
    required this.policyScope,
    required this.policyOwner,
    this.incidents = const [],
    this.tools = const [],
    this.policies = const [],
  });

  factory CompanyHistory.fromJson(Map<String, dynamic> json) {
    return CompanyHistory(
      id: json['id'] ?? json['id']?.toString() ?? '',
      company: json['company'] ?? '', // Add company field
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      industry: json['industry'] ?? '',
      yearEstablished: json['year_established'] ?? json['yearEstablished'] ?? 0,
      numberOfEmployees:
          json['number_of_employees'] ?? json['numberOfEmployees'] ?? 0,
      securityHistory:
          json['security_history'] ?? json['securityHistory'] ?? '',
      currentSecurity:
          json['current_security'] ?? json['currentSecurity'] ?? '',
      lastUpdated: DateTime.tryParse(
              json['last_updated'] ?? json['lastUpdated'] ?? '') ??
          DateTime.now(),
      networkArchitecture:
          json['network_architecture'] ?? json['networkArchitecture'] ?? '',
      incidentId: json['incident_id'] ?? json['incidentId'] ?? '',
      incidentTitle: json['incident_title'] ?? json['incidentTitle'] ?? '',
      incidentDescription:
          json['incident_description'] ?? json['incidentDescription'] ?? '',
      incidentDate: DateTime.tryParse(
              json['incident_date'] ?? json['incidentDate'] ?? '') ??
          DateTime.now(),
      incidentImpact: json['incident_impact'] ?? json['incidentImpact'] ?? '',
      incidentResolution:
          json['incident_resolution'] ?? json['incidentResolution'] ?? '',
      incidentLessonsLearned: json['incident_lessons_learned'] ??
          json['incidentLessonsLearned'] ??
          '',
      toolId: json['tool_id'] ?? json['toolId'] ?? '',
      toolName: json['tool_name'] ?? json['toolName'] ?? '',
      toolCategory: json['tool_category'] ?? json['toolCategory'] ?? '',
      toolVendor: json['tool_vendor'] ?? json['toolVendor'] ?? '',
      toolVersion: json['tool_version'] ?? json['toolVersion'] ?? '',
      toolImplementationDate: DateTime.tryParse(
              json['tool_implementation_date'] ??
                  json['toolImplementationDate'] ??
                  '') ??
          DateTime.now(),
      toolPurpose: json['tool_purpose'] ?? json['toolPurpose'] ?? '',
      toolCoverage: json['tool_coverage'] ?? json['toolCoverage'] ?? '',
      toolIsActive: json['tool_is_active'] ?? json['toolIsActive'] ?? false,
      policyId: json['policy_id'] ?? json['policyId'] ?? '',
      policyTitle: json['policy_title'] ?? json['policyTitle'] ?? '',
      policyDescription:
          json['policy_description'] ?? json['policyDescription'] ?? '',
      policyCreationDate: DateTime.tryParse(json['policy_creation_date'] ??
              json['policyCreationDate'] ??
              '') ??
          DateTime.now(),
      policyLastReviewDate: DateTime.tryParse(json['policy_last_review_date'] ??
              json['policyLastReviewDate'] ??
              '') ??
          DateTime.now(),
      policyDocumentUrl:
          json['policy_document_url'] ?? json['policyDocumentUrl'] ?? '',
      policyScope: json['policy_scope'] ?? json['policyScope'] ?? '',
      policyOwner: json['policy_owner'] ?? json['policyOwner'] ?? '',
      incidents: (json['incidents'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      tools: (json['tools'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      policies: (json['policies'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    final incidentEntry = {
      'incident_id': incidentId,
      'incident_title': incidentTitle,
      'incident_description': incidentDescription,
      'incident_date': incidentDate.toIso8601String(),
      'incident_impact': incidentImpact,
      'incident_resolution': incidentResolution,
      'incident_lessons_learned': incidentLessonsLearned,
    };
    final toolEntry = {
      'tool_id': toolId,
      'tool_name': toolName,
      'tool_category': toolCategory,
      'tool_vendor': toolVendor,
      'tool_version': toolVersion,
      'tool_implementation_date': toolImplementationDate.toIso8601String(),
      'tool_purpose': toolPurpose,
      'tool_coverage': toolCoverage,
      'tool_is_active': toolIsActive,
    };
    final policyEntry = {
      'policy_id': policyId,
      'policy_title': policyTitle,
      'policy_description': policyDescription,
      'policy_creation_date': policyCreationDate.toIso8601String(),
      'policy_last_review_date': policyLastReviewDate.toIso8601String(),
      'policy_document_url': policyDocumentUrl,
      'policy_scope': policyScope,
      'policy_owner': policyOwner,
    };

    return {
      'incident_id': incidentId.isNotEmpty ? incidentId : 'temp-incident-id',
      'tool_id': toolId.isNotEmpty ? toolId : 'temp-tool-id',
      'policy_id': policyId.isNotEmpty ? policyId : 'temp-policy-id',
      'company': company, // Add company field
      'company_name': companyName,
      'industry': industry,
      'year_established': yearEstablished,
      'number_of_employees': numberOfEmployees,
      'security_history': securityHistory,
      'current_security': currentSecurity,
      'last_updated': lastUpdated.toIso8601String(),
      'network_architecture': networkArchitecture,
      'incident_title': incidentTitle,
      'incident_description': incidentDescription,
      'incident_date': incidentDate.toIso8601String(),
      'incident_impact': incidentImpact,
      'incident_resolution': incidentResolution,
      'incident_lessons_learned': incidentLessonsLearned,
      'tool_name': toolName,
      'tool_category': toolCategory,
      'tool_vendor': toolVendor,
      'tool_version': toolVersion,
      'tool_implementation_date': toolImplementationDate.toIso8601String(),
      'tool_purpose': toolPurpose,
      'tool_coverage': toolCoverage,
      'tool_is_active': toolIsActive,
      'policy_title': policyTitle,
      'policy_description': policyDescription,
      'policy_creation_date': policyCreationDate.toIso8601String(),
      'policy_last_review_date': policyLastReviewDate.toIso8601String(),
      'policy_document_url': policyDocumentUrl,
      'policy_scope': policyScope,
      'policy_owner': policyOwner,
      // New arrays; always include, seed with current single entry if any
      'incidents': incidents.isNotEmpty
          ? incidents
          : (incidentTitle.isNotEmpty ? [incidentEntry] : []),
      'tools':
          tools.isNotEmpty ? tools : (toolName.isNotEmpty ? [toolEntry] : []),
      'policies': policies.isNotEmpty
          ? policies
          : (policyTitle.isNotEmpty ? [policyEntry] : []),
    };
  }

  Map<String, dynamic> toAIAnalysisFormat() {
    return {
      'Company Overview': {
        'ID': id,
        'Name': companyName,
        'Industry': industry,
        'Year Established': yearEstablished,
        'Employees': numberOfEmployees,
        'Security History': securityHistory,
        'Current Security': currentSecurity,
        'Last Updated': lastUpdated.toIso8601String(),
        'Network Architecture': networkArchitecture,
      },
      'Security Incident': {
        'ID': incidentId,
        'Title': incidentTitle,
        'Description': incidentDescription,
        'Date': incidentDate.toIso8601String(),
        'Impact': incidentImpact,
        'Resolution': incidentResolution,
        'Lessons Learned': incidentLessonsLearned,
      },
      'Security Tool': {
        'ID': toolId,
        'Name': toolName,
        'Category': toolCategory,
        'Vendor': toolVendor,
        'Version': toolVersion,
        'Implementation Date': toolImplementationDate.toIso8601String(),
        'Purpose': toolPurpose,
        'Coverage': toolCoverage,
        'Is Active': toolIsActive,
      },
      'Policy Document': {
        'ID': policyId,
        'Title': policyTitle,
        'Description': policyDescription,
        'Creation Date': policyCreationDate.toIso8601String(),
        'Last Review Date': policyLastReviewDate.toIso8601String(),
        'Document URL': policyDocumentUrl,
        'Scope': policyScope,
        'Owner': policyOwner,
      },
    };
  }
}

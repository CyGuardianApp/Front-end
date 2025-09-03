import 'dart:convert';

/// Utility class for data validation
class Validators {
  /// Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  /// Password validation regex (at least 6 characters, one letter, one number)
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{6,}$',
  );

  /// UUID validation regex
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    return _passwordRegex.hasMatch(password);
  }

  /// Validate UUID format
  static bool isValidUuid(String uuid) {
    if (uuid.isEmpty) return false;
    return _uuidRegex.hasMatch(uuid);
  }

  /// Validate required field
  static bool isRequired(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validate minimum length
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  /// Validate maximum length
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }

  /// Validate numeric value
  static bool isNumeric(String value) {
    if (value.isEmpty) return false;
    return double.tryParse(value) != null;
  }

  /// Validate integer value
  static bool isInteger(String value) {
    if (value.isEmpty) return false;
    return int.tryParse(value) != null;
  }

  /// Validate positive number
  static bool isPositiveNumber(String value) {
    if (value.isEmpty) return false;
    final number = double.tryParse(value);
    return number != null && number > 0;
  }

  /// Validate date format (ISO 8601)
  static bool isValidDate(String dateString) {
    if (dateString.isEmpty) return false;
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate phone number (basic format)
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Validate domain name
  static bool isValidDomain(String domain) {
    if (domain.isEmpty) return false;
    final domainRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return domainRegex.hasMatch(domain);
  }

  /// Validate JSON string
  static bool isValidJson(String jsonString) {
    if (jsonString.isEmpty) return false;
    try {
      // Try to parse as JSON
      final decoded = jsonDecode(jsonString);
      return decoded != null;
    } catch (e) {
      return false;
    }
  }

  /// Validate role string
  static bool isValidRole(String role) {
    const validRoles = ['cto', 'cyberSecurityHead', 'subDepartmentHead'];
    return validRoles.contains(role);
  }

  /// Validate questionnaire status
  static bool isValidQuestionnaireStatus(String status) {
    const validStatuses = ['draft', 'published', 'completed', 'archived'];
    return validStatuses.contains(status);
  }

  /// Validate question type
  static bool isValidQuestionType(String type) {
    const validTypes = [
      'text',
      'multipleChoice',
      'checkbox',
      'scale',
      'yesNo',
      'date'
    ];
    return validTypes.contains(type);
  }

  /// Validate risk level
  static bool isValidRiskLevel(String level) {
    const validLevels = ['Low', 'Medium', 'High', 'Critical'];
    return validLevels.contains(level);
  }

  /// Validate severity level
  static bool isValidSeverity(String severity) {
    const validSeverities = ['Low', 'Medium', 'High', 'Critical'];
    return validSeverities.contains(severity);
  }

  /// Comprehensive validation result
  static ValidationResult validateField({
    required String value,
    bool required = false,
    int? minLength,
    int? maxLength,
    String?
        type, // 'email', 'password', 'uuid', 'numeric', 'integer', 'date', 'url', 'phone', 'domain'
    List<String>? allowedValues,
  }) {
    // Check if required
    if (required && !isRequired(value)) {
      return ValidationResult(false, 'This field is required');
    }

    // Skip other validations if value is empty and not required
    if (value.isEmpty && !required) {
      return ValidationResult(true, '');
    }

    // Check minimum length
    if (minLength != null && !hasMinLength(value, minLength)) {
      return ValidationResult(false, 'Minimum length is $minLength characters');
    }

    // Check maximum length
    if (maxLength != null && !hasMaxLength(value, maxLength)) {
      return ValidationResult(false, 'Maximum length is $maxLength characters');
    }

    // Check type-specific validations
    switch (type) {
      case 'email':
        if (!isValidEmail(value)) {
          return ValidationResult(false, 'Please enter a valid email address');
        }
        break;
      case 'password':
        if (!isValidPassword(value)) {
          return ValidationResult(false,
              'Password must be at least 6 characters with letters and numbers');
        }
        break;
      case 'uuid':
        if (!isValidUuid(value)) {
          return ValidationResult(false, 'Invalid ID format');
        }
        break;
      case 'numeric':
        if (!isNumeric(value)) {
          return ValidationResult(false, 'Please enter a valid number');
        }
        break;
      case 'integer':
        if (!isInteger(value)) {
          return ValidationResult(false, 'Please enter a valid integer');
        }
        break;
      case 'date':
        if (!isValidDate(value)) {
          return ValidationResult(false, 'Please enter a valid date');
        }
        break;
      case 'url':
        if (!isValidUrl(value)) {
          return ValidationResult(false, 'Please enter a valid URL');
        }
        break;
      case 'phone':
        if (!isValidPhoneNumber(value)) {
          return ValidationResult(false, 'Please enter a valid phone number');
        }
        break;
      case 'domain':
        if (!isValidDomain(value)) {
          return ValidationResult(false, 'Please enter a valid domain name');
        }
        break;
    }

    // Check allowed values
    if (allowedValues != null && !allowedValues.contains(value)) {
      return ValidationResult(
          false, 'Invalid value. Allowed values: ${allowedValues.join(', ')}');
    }

    return ValidationResult(true, '');
  }

  /// Validate user registration data
  static Map<String, ValidationResult> validateUserRegistration({
    required String email,
    required String password,
    required String role,
    String? name,
    String? departmentName,
  }) {
    return {
      'email': validateField(value: email, required: true, type: 'email'),
      'password':
          validateField(value: password, required: true, type: 'password'),
      'role': validateField(
          value: role,
          required: true,
          allowedValues: ['cto', 'cyberSecurityHead', 'subDepartmentHead']),
      'name': validateField(
          value: name ?? '', required: false, minLength: 2, maxLength: 100),
      'departmentName': validateField(
          value: departmentName ?? '',
          required: false,
          minLength: 2,
          maxLength: 100),
    };
  }

  /// Validate questionnaire data
  static Map<String, ValidationResult> validateQuestionnaire({
    required String title,
    required String description,
    required String departmentId,
    required List<Map<String, dynamic>> questions,
  }) {
    final results = <String, ValidationResult>{};

    results['title'] = validateField(
        value: title, required: true, minLength: 3, maxLength: 200);
    results['description'] = validateField(
        value: description, required: true, minLength: 10, maxLength: 1000);
    results['departmentId'] =
        validateField(value: departmentId, required: true, type: 'domain');

    // Validate questions
    if (questions.isEmpty) {
      results['questions'] =
          ValidationResult(false, 'At least one question is required');
    } else {
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final questionResults = validateQuestion(question);
        for (final entry in questionResults.entries) {
          results['questions[$i].${entry.key}'] = entry.value;
        }
      }
    }

    return results;
  }

  /// Validate individual question
  static Map<String, ValidationResult> validateQuestion(
      Map<String, dynamic> question) {
    return {
      'text': validateField(
          value: question['text'] ?? '',
          required: true,
          minLength: 5,
          maxLength: 500),
      'type': validateField(
          value: question['type'] ?? '',
          required: true,
          allowedValues: [
            'text',
            'multipleChoice',
            'checkbox',
            'scale',
            'yesNo',
            'date'
          ]),
      'required': ValidationResult(true, ''), // Boolean field, always valid
    };
  }

  /// Validate company history data
  static Map<String, ValidationResult> validateCompanyHistory({
    required String companyName,
    required String industry,
    required int yearEstablished,
    required int numberOfEmployees,
  }) {
    return {
      'companyName': validateField(
          value: companyName, required: true, minLength: 2, maxLength: 200),
      'industry': validateField(
          value: industry, required: true, minLength: 2, maxLength: 100),
      'yearEstablished': validateField(
          value: yearEstablished.toString(), required: true, type: 'integer'),
      'numberOfEmployees': validateField(
          value: numberOfEmployees.toString(), required: true, type: 'integer'),
    };
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult(this.isValid, this.message);

  @override
  String toString() => isValid ? 'Valid' : message;
}

/// Extension for easy validation
extension StringValidation on String {
  bool get isValidEmail => Validators.isValidEmail(this);
  bool get isValidPassword => Validators.isValidPassword(this);
  bool get isValidUuid => Validators.isValidUuid(this);
  bool get isValidUrl => Validators.isValidUrl(this);
  bool get isValidDate => Validators.isValidDate(this);
  bool get isValidPhoneNumber => Validators.isValidPhoneNumber(this);
  bool get isValidDomain => Validators.isValidDomain(this);
  bool get isRequired => Validators.isRequired(this);
}

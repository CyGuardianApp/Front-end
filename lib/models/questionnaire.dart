import 'dart:convert';

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options;
  final dynamic answer;
  final bool required;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.answer,
    this.required = true,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    dynamic parsedAnswer = json['answer'];

    // جرّب ترجّع DateTime لو كانت String صالحة
    if (parsedAnswer is String && DateTime.tryParse(parsedAnswer) != null) {
      parsedAnswer = DateTime.parse(parsedAnswer);
    }

    return Question(
      id: json['id'],
      text: json['text'],
      type: QuestionTypeExtension.fromString(json['type']),
      options:
          json['options'] != null ? List<String>.from(json['options']) : null,
      answer: parsedAnswer,
      required: json['required'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    dynamic encodedAnswer = answer;

    // Handle DateTime conversion
    if (encodedAnswer is DateTime) {
      encodedAnswer = encodedAnswer.toIso8601String();
    }

    // Handle other potential non-serializable objects
    if (encodedAnswer != null && !_isJsonSerializable(encodedAnswer)) {
      encodedAnswer = encodedAnswer.toString();
    }

    return {
      'id': id,
      'text': text,
      'type': type.toString().split('.').last,
      'options': options,
      'answer': encodedAnswer,
      'required': required,
    };
  }

  bool _isJsonSerializable(dynamic value) {
    return value is String ||
        value is int ||
        value is double ||
        value is bool ||
        value == null ||
        (value is List && value.every((item) => _isJsonSerializable(item))) ||
        (value is Map &&
            value.keys.every((key) => key is String) &&
            value.values.every((value) => _isJsonSerializable(value)));
  }

  Question copyWith({
    String? id,
    String? text,
    QuestionType? type,
    List<String>? options,
    dynamic answer,
    bool? required,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      required: required ?? this.required,
    );
  }
}

enum QuestionType {
  text,
  multipleChoice,
  checkbox,
  scale,
  yesNo,
  date,
}

extension QuestionTypeExtension on QuestionType {
  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (type) => type.toString().split('.').last == value,
      orElse: () => QuestionType.text,
    );
  }
}

class Questionnaire {
  final String id;
  final String title;
  final String description;
  final String departmentId;
  final String createdBy;
  final DateTime createdAt;
  final List<Question> questions;
  final QuestionnaireStatus status;

  Questionnaire({
    required this.id,
    required this.title,
    required this.description,
    required this.departmentId,
    required this.createdBy,
    required this.createdAt,
    required this.questions,
    this.status = QuestionnaireStatus.draft,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    return Questionnaire(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      departmentId: json['department_id'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      questions:
          (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
      status: QuestionnaireStatusExtension.fromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'id': id,
        'title': title,
        'description': description,
        'department_id': departmentId,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'status': status.toString().split('.').last,
      };
    } catch (e) {
      print('Error in Questionnaire.toJson(): $e');
      rethrow;
    }
  }

  Questionnaire copyWith({
    String? id,
    String? title,
    String? description,
    String? departmentId,
    String? createdBy,
    DateTime? createdAt,
    List<Question>? questions,
    QuestionnaireStatus? status,
  }) {
    return Questionnaire(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      departmentId: departmentId ?? this.departmentId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
      status: status ?? this.status,
    );
  }
}

enum QuestionnaireStatus {
  draft,
  published,
  completed,
  archived,
}

extension QuestionnaireStatusExtension on QuestionnaireStatus {
  static QuestionnaireStatus fromString(String value) {
    return QuestionnaireStatus.values.firstWhere(
      (status) => status.toString().split('.').last == value,
      orElse: () => QuestionnaireStatus.draft,
    );
  }
}

class QuestionnaireResponse {
  final String id;
  final String questionnaireId;
  final String respondentId;
  final DateTime submittedAt;
  final Map<String, dynamic> responses;

  QuestionnaireResponse({
    required this.id,
    required this.questionnaireId,
    required this.respondentId,
    required this.submittedAt,
    required this.responses,
  });

  factory QuestionnaireResponse.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResponse(
      id: json['id'],
      questionnaireId: json['questionnaire_id'],
      respondentId: json['respondent_id'],
      submittedAt: DateTime.parse(json['submitted_at']),
      responses: json['responses'] is String
          ? jsonDecode(json['responses'])
          : Map<String, dynamic>.from(json['responses']),
    );
  }

  Map<String, dynamic> toJson() {
    final encodedResponses = responses.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      return MapEntry(key, value);
    });

    return {
      'id': id,
      'questionnaire_id': questionnaireId,
      'respondent_id': respondentId,
      'submitted_at': submittedAt.toIso8601String(),
      'responses': encodedResponses,
    };
  }
}

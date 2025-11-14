import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/questionnaire.dart';
import '../providers/questionnaire_provider.dart';

class ResponseDetailScreen extends StatelessWidget {
  final String responseId;

  const ResponseDetailScreen({
    super.key,
    required this.responseId,
  });

  @override
  Widget build(BuildContext context) {
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);

    // Get the response
    final response = questionnaireProvider.getResponseById(responseId);
    if (response == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Response Details')),
        body: const Center(child: Text('Response not found')),
      );
    }

    // Get the questionnaire
    final questionnaire =
        questionnaireProvider.getQuestionnaireById(response.questionnaireId);
    if (questionnaire == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Response Details')),
        body: const Center(child: Text('Questionnaire not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Responses'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Questionnaire header
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                return Card(
                  color: isDark ? Colors.grey[800] : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questionnaire.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          questionnaire.description,
                          style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          color: isDark ? Colors.grey[700] : null,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Submitted on:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _formatDateTime(response.submittedAt),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Responses
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Text(
                  'Your Answers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Display each question and answer
            ...questionnaire.questions.map((question) {
              return _buildQuestionResponseCard(
                  context, question, response.responses[question.id]);
            }),

            const SizedBox(height: 24),

            // Action buttons
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionResponseCard(
      BuildContext context, Question question, dynamic answer) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? Colors.grey[800] : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              color: isDark ? Colors.grey[700] : null,
            ),
            const SizedBox(height: 8),
            _buildAnswerDisplay(context, question, answer),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerDisplay(
      BuildContext context, Question question, dynamic answer) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (answer == null) {
      return Text(
        'Not answered',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.grey[400] : Colors.grey,
        ),
      );
    }

    switch (question.type) {
      case QuestionType.text:
        return Text(
          answer.toString(),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
          ),
        );

      case QuestionType.multipleChoice:
        return Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              answer,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        );

      case QuestionType.checkbox:
        if (answer is! List) {
          return Text(
            'Invalid answer format',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: (answer).map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Theme.of(context).primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    option,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case QuestionType.scale:
        return Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            return Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rating <= answer
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.2),
              ),
              child: Center(
                child: Text(
                  '$rating',
                  style: TextStyle(
                    color: rating <= answer
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        );

      case QuestionType.yesNo:
        return Row(
          children: [
            Icon(
              answer == true ? Icons.check_circle : Icons.cancel,
              color: answer == true ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              answer == true ? 'Yes' : 'No',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: answer == true ? Colors.green : Colors.red,
              ),
            ),
          ],
        );

      case QuestionType.date:
        if (answer is! DateTime) {
          // Try to parse it
          try {
            final date = DateTime.parse(answer.toString());
            return Text(
              _formatDate(date),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            );
          } catch (e) {
            return Text(
              'Invalid date format',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            );
          }
        }
        return Text(
          _formatDate(answer),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
          ),
        );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year at $hour:$minute';
  }
}

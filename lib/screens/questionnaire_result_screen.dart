import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/questionnaire_provider.dart';
import 'questionnaire_list_screen.dart';
import 'response_detail_screen.dart';

class QuestionnaireResultScreen extends StatelessWidget {
  final String responseId;

  const QuestionnaireResultScreen({
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
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('Response not found')),
      );
    }

    // Get the questionnaire
    final questionnaire =
        questionnaireProvider.getQuestionnaireById(response.questionnaireId);
    if (questionnaire == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('Questionnaire not found')),
      );
    }

    // Calculate completeness
    final totalRequired =
        questionnaire.questions.where((q) => q.required).length;
    final answeredRequired = questionnaire.questions
        .where((q) => q.required && response.responses.containsKey(q.id))
        .length;
    final completionPercentage = (answeredRequired / totalRequired) * 100;

    return WillPopScope(
      onWillPop: () async {
        // Navigate to questionnaire list on back
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const QuestionnaireListScreen()));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Submission Complete'),
          // Prevent going back with the app bar back button
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Thank You!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your responses have been submitted successfully.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Submitted on ${_formatDateTime(response.submittedAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Questionnaire summary
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Questionnaire Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow('Title', questionnaire.title),
                      _buildInfoRow(
                          'Completion', '${completionPercentage.toInt()}%'),
                      _buildInfoRow('Questions Answered',
                          '${response.responses.length} of ${questionnaire.questions.length}'),
                      _buildInfoRow('Required Questions',
                          '$answeredRequired of $totalRequired'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // What happens next
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What Happens Next?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          child: const Text('1'),
                        ),
                        title: const Text('Analysis'),
                        subtitle: const Text(
                            'Your responses will be analyzed to identify potential security risks.'),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          child: const Text('2'),
                        ),
                        title: const Text('Recommendations'),
                        subtitle: const Text(
                            'Cybersecurity recommendations will be generated based on your responses.'),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          child: const Text('3'),
                        ),
                        title: const Text('Review'),
                        subtitle: const Text(
                            'The Cybersecurity Head will review the analysis and recommendations.'),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          child: const Text('4'),
                        ),
                        title: const Text('Implementation'),
                        subtitle: const Text(
                            'Approved recommendations will be implemented to improve security.'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to response details screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResponseDetailScreen(
                              responseId: responseId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Your Responses'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        // Navigate back to questionnaire list
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const QuestionnaireListScreen()));
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('Back to Questionnaires'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/questionnaire.dart';
import '../providers/questionnaire_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/question_answer_widget.dart';
import 'questionnaire_list_screen.dart';

class AnswerQuestionnaireScreen extends StatefulWidget {
  final String questionnaireId;

  const AnswerQuestionnaireScreen({
    super.key,
    required this.questionnaireId,
  });

  @override
  _AnswerQuestionnaireScreenState createState() =>
      _AnswerQuestionnaireScreenState();
}

class _AnswerQuestionnaireScreenState extends State<AnswerQuestionnaireScreen> {
  final Map<String, dynamic> _answers = {};
  bool _isSubmitting = false;
  int _currentQuestionIndex = 0;
  PageController _pageController = PageController();
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Check if there are saved draft responses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedResponses();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedResponses() async {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) return;

    final savedResponses = questionnaireProvider.getDraftResponses(
        widget.questionnaireId, authProvider.user!.id);

    if (savedResponses != null) {
      // Ask user if they want to continue from saved draft
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resume Draft?'),
          content: const Text(
              'Would you like to continue from your saved progress?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Start Over'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _answers.addAll(savedResponses);
                });
                Navigator.pop(context);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  void _setAnswer(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
    });

    // Auto-save draft after each answer
    _saveDraft();
  }

  Future<void> _saveDraft() async {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) return;

    await questionnaireProvider.saveDraftResponses(
        widget.questionnaireId, authProvider.user!.id, _answers);
  }

  bool _validateCurrentQuestion(Question question) {
    if (!question.required) return true;

    if (!_answers.containsKey(question.id) || _answers[question.id] == null) {
      return false;
    }

    switch (question.type) {
      case QuestionType.text:
        return _answers[question.id].toString().trim().isNotEmpty;
      case QuestionType.multipleChoice:
      case QuestionType.yesNo:
      case QuestionType.date:
        return _answers[question.id] != null;
      case QuestionType.checkbox:
        List<dynamic> selectedOptions = _answers[question.id] as List<dynamic>;
        return selectedOptions.isNotEmpty;
      case QuestionType.scale:
        return _answers[question.id] != null && _answers[question.id] > 0;
      default:
        return true;
    }
  }

  bool _validateAllQuestions(List<Question> questions) {
    for (var question in questions) {
      if (question.required && !_validateCurrentQuestion(question)) {
        return false;
      }
    }
    return true;
  }

  void _nextQuestion(int totalQuestions) {
    final questionnaire =
        Provider.of<QuestionnaireProvider>(context, listen: false)
            .getQuestionnaireById(widget.questionnaireId);

    if (questionnaire == null) return;

    final currentQuestion = questionnaire.questions[_currentQuestionIndex];

    if (currentQuestion.required &&
        !_validateCurrentQuestion(currentQuestion)) {
      setState(() {
        _showValidationErrors = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please answer this required question')));

      return;
    }

    if (_currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showValidationErrors = false;
      });
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _showValidationErrors = false;
      });
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitQuestionnaire(
      BuildContext context, Questionnaire questionnaire) async {
    // Check if all required questions are answered
    if (!_validateAllQuestions(questionnaire.questions)) {
      setState(() {
        _showValidationErrors = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please answer all required questions')));

      // Find first unanswered required question and navigate to it
      for (int i = 0; i < questionnaire.questions.length; i++) {
        if (questionnaire.questions[i].required &&
            !_validateCurrentQuestion(questionnaire.questions[i])) {
          setState(() {
            _currentQuestionIndex = i;
          });
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          break;
        }
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final questionnaireProvider =
          Provider.of<QuestionnaireProvider>(context, listen: false);

      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')));
        return;
      }

      // Create questionnaire response
      final response = QuestionnaireResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        questionnaireId: questionnaire.id,
        respondentId: authProvider.user!.id,
        submittedAt: DateTime.now(),
        responses: Map<String, dynamic>.from(_answers),
      );

      // Submit response to database
      final success =
          await questionnaireProvider.submitResponse(response, context);

      if (success && mounted) {
        // Clear draft responses
        questionnaireProvider.clearDraftResponses(
            questionnaire.id, authProvider.user!.id);

        // Update questionnaire status to completed
        final updatedQuestionnaire = questionnaire.copyWith(
          status: QuestionnaireStatus.completed,
        );
        await questionnaireProvider.updateQuestionnaire(
            updatedQuestionnaire, context);

        // Refresh questionnaire list and responses so CISO can see the new response
        QuestionnaireListScreen.refreshQuestionnaireList(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questionnaire submitted successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(questionnaireProvider.errorMessage ??
                  'Failed to submit questionnaire')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionnaireProvider = Provider.of<QuestionnaireProvider>(context);
    final questionnaire =
        questionnaireProvider.getQuestionnaireById(widget.questionnaireId);

    if (questionnaire == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Questionnaire')),
        body: const Center(child: Text('Questionnaire not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(questionnaire.title),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => _saveDraft(),
            child: const Text(
              'Save Draft',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) /
                      questionnaire.questions.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),

                // Question count and progress text
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${questionnaire.questions.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${((_currentQuestionIndex + 1) / questionnaire.questions.length * 100).toInt()}% Complete',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Questionnaire description
                if (_currentQuestionIndex == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              questionnaire.description,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Questions
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questionnaire.questions.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final question = questionnaire.questions[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            QuestionAnswerWidget(
                              question: question,
                              answer: _answers[question.id],
                              onAnswerChanged: (answer) =>
                                  _setAnswer(question.id, answer),
                              showValidationError: _showValidationErrors &&
                                  question.required &&
                                  !_validateCurrentQuestion(question),
                            ),
                            if (_showValidationErrors &&
                                question.required &&
                                !_validateCurrentQuestion(question))
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'This question requires an answer',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _currentQuestionIndex > 0
                            ? _previousQuestion
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                        child: Text('Previous'),
                      ),
                      if (_currentQuestionIndex ==
                          questionnaire.questions.length - 1)
                        ElevatedButton(
                          onPressed: () =>
                              _submitQuestionnaire(context, questionnaire),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text('Submit'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () =>
                              _nextQuestion(questionnaire.questions.length),
                          child: const Text('Next'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

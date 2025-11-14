import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/questionnaire.dart';
import '../providers/questionnaire_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/question_editor.dart';

class CreateQuestionnaireScreen extends StatefulWidget {
  final String? questionnaireId;

  const CreateQuestionnaireScreen({super.key, this.questionnaireId});

  @override
  _CreateQuestionnaireScreenState createState() =>
      _CreateQuestionnaireScreenState();
}

class _CreateQuestionnaireScreenState extends State<CreateQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedDepartmentId;
  List<Question> _questions = [];
  QuestionnaireStatus _status = QuestionnaireStatus.draft;
  bool _isLoading = false;
  bool _isInitialized = false;
  List<DropdownMenuItem<String>> _departmentItems = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadDepartmentItems();
      if (widget.questionnaireId != null) {
        _loadExistingQuestionnaire();
      }
      _isInitialized = true;
    }
  }

  Future<void> _loadDepartmentItems() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return;

    final organization = await authProvider
        .findOrganizationByDomainWithFetch(currentUser.domain);
    if (organization == null) return;

    setState(() {
      _departmentItems = organization.subDepartmentHeads.map((subDept) {
        final name = subDept.departmentName ?? "${subDept.name}'s Department";
        return DropdownMenuItem<String>(
          value: subDept.id,
          child: Text(name),
        );
      }).toList();
    });
  }

  void _loadExistingQuestionnaire() {
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);
    final questionnaire =
        questionnaireProvider.getQuestionnaireById(widget.questionnaireId!);

    if (questionnaire != null) {
      _titleController.text = questionnaire.title;
      _descriptionController.text = questionnaire.description;
      _selectedDepartmentId = questionnaire.departmentId;
      _questions = List.from(questionnaire.questions);
      _status = questionnaire.status;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        Question(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '',
          type: QuestionType.text,
          required: true,
        ),
      );
    });
  }

  void _addQuestionAfter(int index) {
    setState(() {
      _questions.insert(
        index + 1,
        Question(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '',
          type: QuestionType.text,
          required: true,
        ),
      );
    });
  }

  void _updateQuestion(int index, Question updatedQuestion) {
    setState(() {
      _questions[index] = updatedQuestion;
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _moveQuestionUp(int index) {
    if (index > 0) {
      setState(() {
        final question = _questions.removeAt(index);
        _questions.insert(index - 1, question);
      });
    }
  }

  void _moveQuestionDown(int index) {
    if (index < _questions.length - 1) {
      setState(() {
        final question = _questions.removeAt(index);
        _questions.insert(index + 1, question);
      });
    }
  }

  Future<void> _saveQuestionnaire() async {
    if (!_formKey.currentState!.validate()) return;

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} is empty')),
        );
        return;
      }

      if (_questions[i].type == QuestionType.multipleChoice ||
          _questions[i].type == QuestionType.checkbox) {
        if (_questions[i].options == null || _questions[i].options!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Question ${i + 1} needs options')),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final questionnaireProvider =
          Provider.of<QuestionnaireProvider>(context, listen: false);

      final questionnaire = Questionnaire(
        id: widget.questionnaireId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        departmentId: _selectedDepartmentId!,
        createdBy: authProvider.user!.email,
        createdAt: DateTime.now(),
        questions: _questions,
        status: _status,
      );

      bool success = widget.questionnaireId == null
          ? await questionnaireProvider.createQuestionnaire(
              questionnaire, context)
          : await questionnaireProvider.updateQuestionnaire(
              questionnaire, context);

      if (success && mounted) {
        // Refresh the questionnaire list
        await questionnaireProvider.fetchAllQuestionnaires(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questionnaire saved successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  questionnaireProvider.errorMessage ?? 'An error occurred')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.questionnaireId == null
            ? 'Create Questionnaire'
            : 'Edit Questionnaire'),
        actions: [
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return TextButton(
                onPressed: _isLoading ? null : _saveQuestionnaire,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter a title'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter a description'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Target Department',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDepartmentId,
                      items: _departmentItems,
                      onChanged: (value) {
                        setState(() => _selectedDepartmentId = value);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a department' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<QuestionnaireStatus>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      value: _status,
                      items: QuestionnaireStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Questions',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                ElevatedButton.icon(
                                  onPressed: _addQuestion,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Question'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _questions.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 32.0),
                                      child: Text(
                                        'No questions added yet',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _questions.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(),
                                    itemBuilder: (context, index) {
                                      return QuestionEditor(
                                        question: _questions[index],
                                        index: index,
                                        onUpdate: (q) =>
                                            _updateQuestion(index, q),
                                        onRemove: () => _removeQuestion(index),
                                        onMoveUp: () => _moveQuestionUp(index),
                                        onMoveDown: () =>
                                            _moveQuestionDown(index),
                                        onAddAfter: () =>
                                            _addQuestionAfter(index),
                                      );
                                    },
                                  ),
                            if (_questions.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _addQuestion,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Question'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}

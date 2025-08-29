import 'package:flutter/material.dart';
import '../models/questionnaire.dart';

class QuestionEditor extends StatefulWidget {
  final Question question;
  final int index;
  final Function(Question) onUpdate;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onAddAfter; // Add this property

  const QuestionEditor({
    super.key,
    required this.question,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddAfter, // Add this parameter
  });

  @override
  _QuestionEditorState createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  late TextEditingController _questionTextController;
  late List<TextEditingController> _optionControllers;
  late QuestionType _selectedType;
  late bool _isRequired;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController(text: widget.question.text);
    _selectedType = widget.question.type;
    _isRequired = widget.question.required;

    // Initialize option controllers if needed
    _optionControllers = [];
    if (widget.question.options != null) {
      for (var option in widget.question.options!) {
        _optionControllers.add(TextEditingController(text: option));
      }
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(QuestionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _questionTextController.text = widget.question.text;
      _selectedType = widget.question.type;
      _isRequired = widget.question.required;

      // Update option controllers
      for (var controller in _optionControllers) {
        controller.dispose();
      }
      _optionControllers = [];
      if (widget.question.options != null) {
        for (var option in widget.question.options!) {
          _optionControllers.add(TextEditingController(text: option));
        }
      }
    }
  }

  void _updateQuestion() {
    // Update with current values
    List<String>? options;
    if (_selectedType == QuestionType.multipleChoice ||
        _selectedType == QuestionType.checkbox) {
      options = _optionControllers.map((c) => c.text.trim()).toList();
    }

    final updatedQuestion = widget.question.copyWith(
      text: _questionTextController.text.trim(),
      type: _selectedType,
      options: options,
      required: _isRequired,
    );

    widget.onUpdate(updatedQuestion);
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
    _updateQuestion();
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
    _updateQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: widget.onMoveUp,
                      tooltip: 'Move up',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: widget.onMoveDown,
                      tooltip: 'Move down',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: widget.onAddAfter,
                      tooltip: 'Add question after this one',
                      color: Colors.green,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: widget.onRemove,
                      tooltip: 'Remove question',
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question text field
            TextFormField(
              controller: _questionTextController,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                hintText: 'Enter your question here',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updateQuestion(),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Question type dropdown
            DropdownButtonFormField<QuestionType>(
              decoration: const InputDecoration(
                labelText: 'Question Type',
                border: OutlineInputBorder(),
              ),
              value: _selectedType,
              items: QuestionType.values.map((type) {
                String displayName = '';
                switch (type) {
                  case QuestionType.text:
                    displayName = 'Text';
                    break;
                  case QuestionType.multipleChoice:
                    displayName = 'Multiple Choice (Single Answer)';
                    break;
                  case QuestionType.checkbox:
                    displayName = 'Checkbox (Multiple Answers)';
                    break;
                  case QuestionType.scale:
                    displayName = 'Scale (1-5)';
                    break;
                  case QuestionType.yesNo:
                    displayName = 'Yes/No';
                    break;
                  case QuestionType.date:
                    displayName = 'Date';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;

                    // Initialize options if needed
                    if ((value == QuestionType.multipleChoice ||
                            value == QuestionType.checkbox) &&
                        _optionControllers.isEmpty) {
                      _optionControllers
                          .add(TextEditingController(text: 'Option 1'));
                      _optionControllers
                          .add(TextEditingController(text: 'Option 2'));
                    }
                  });
                  _updateQuestion();
                }
              },
            ),
            const SizedBox(height: 16),

            // Required checkbox
            Row(
              children: [
                Checkbox(
                  value: _isRequired,
                  onChanged: (value) {
                    setState(() {
                      _isRequired = value ?? true;
                    });
                    _updateQuestion();
                  },
                ),
                const Text('Required'),
              ],
            ),

            // Options section (for multiple choice and checkbox)
            if (_selectedType == QuestionType.multipleChoice ||
                _selectedType == QuestionType.checkbox) ...[
              const SizedBox(height: 16),
              Text(
                'Options',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => _updateQuestion(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _optionControllers.length >
                                2 // Ensure at least two options
                            ? () => _removeOption(index)
                            : null,
                        tooltip: 'Remove option',
                        color: Colors.red,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

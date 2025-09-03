import 'package:flutter/material.dart';
import '../models/questionnaire.dart';

class QuestionAnswerWidget extends StatefulWidget {
  final Question question;
  final dynamic answer;
  final Function(dynamic) onAnswerChanged;
  final bool showValidationError;

  const QuestionAnswerWidget({
    super.key,
    required this.question,
    this.answer,
    required this.onAnswerChanged,
    this.showValidationError = false,
  });

  @override
  _QuestionAnswerWidgetState createState() => _QuestionAnswerWidgetState();
}

class _QuestionAnswerWidgetState extends State<QuestionAnswerWidget> {
  late TextEditingController _textController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.answer != null && widget.question.type == QuestionType.text
          ? widget.answer.toString()
          : '',
    );

    if (widget.question.type == QuestionType.date && widget.answer != null) {
      if (widget.answer is DateTime) {
        _selectedDate = widget.answer;
      } else if (widget.answer is String) {
        try {
          _selectedDate = DateTime.parse(widget.answer);
        } catch (e) {
          _selectedDate = null;
        }
      }
    }
  }

  @override
  void didUpdateWidget(QuestionAnswerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer &&
        widget.question.type == QuestionType.text) {
      _textController.text = widget.answer?.toString() ?? '';
    }

    if (widget.question.type == QuestionType.date &&
        oldWidget.answer != widget.answer) {
      if (widget.answer is DateTime) {
        _selectedDate = widget.answer;
      } else if (widget.answer is String) {
        try {
          _selectedDate = DateTime.parse(widget.answer);
        } catch (e) {
          _selectedDate = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onAnswerChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.showValidationError
              ? Colors.red
              : Colors.grey.withOpacity(0.2),
          width: widget.showValidationError ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.question.text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.question.required)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.showValidationError
                          ? Colors.red.withOpacity(0.1)
                          : Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.showValidationError
                            ? Colors.red
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        color: widget.showValidationError
                            ? Colors.red
                            : Colors.red.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Different input types based on question type
            _buildAnswerInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput() {
    switch (widget.question.type) {
      case QuestionType.text:
        return TextFormField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Enter your answer',
            border: const OutlineInputBorder(),
            errorText:
                widget.showValidationError ? 'An answer is required' : null,
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
          onChanged: (value) {
            widget.onAnswerChanged(value);
          },
        );

      case QuestionType.multipleChoice:
        if (widget.question.options == null ||
            widget.question.options!.isEmpty) {
          return const Text('No options available');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showValidationError)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Please select an option',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ...widget.question.options!.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: widget.answer,
                onChanged: (value) {
                  widget.onAnswerChanged(value);
                },
                activeColor: Theme.of(context).primaryColor,
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: widget.answer == option
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
              );
            }),
          ],
        );

      case QuestionType.checkbox:
        if (widget.question.options == null ||
            widget.question.options!.isEmpty) {
          return const Text('No options available');
        }

        List<String> selectedOptions = [];
        if (widget.answer is List) {
          selectedOptions = List<String>.from(widget.answer);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showValidationError)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Please select at least one option',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ...widget.question.options!.map((option) {
              return CheckboxListTile(
                title: Text(option),
                value: selectedOptions.contains(option),
                onChanged: (bool? value) {
                  if (value == true) {
                    selectedOptions.add(option);
                  } else {
                    selectedOptions.remove(option);
                  }
                  widget.onAnswerChanged(selectedOptions);
                },
                activeColor: Theme.of(context).primaryColor,
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: selectedOptions.contains(option)
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
              );
            }),
          ],
        );

      case QuestionType.scale:
        int value = widget.answer != null ? widget.answer as int : 0;

        return Column(
          children: [
            if (widget.showValidationError)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Please select a value',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return InkWell(
                  onTap: () {
                    widget.onAnswerChanged(rating);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value == rating
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        '$rating',
                        style: TextStyle(
                          color: value == rating ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low', style: TextStyle(color: Colors.grey[600])),
                Text('High', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        );

      case QuestionType.yesNo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showValidationError)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Please select Yes or No',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Yes'),
                    value: true,
                    groupValue: widget.answer,
                    onChanged: (value) {
                      widget.onAnswerChanged(value);
                    },
                    activeColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: widget.answer == true
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('No'),
                    value: false,
                    groupValue: widget.answer,
                    onChanged: (value) {
                      widget.onAnswerChanged(value);
                    },
                    activeColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: widget.answer == false
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );

      case QuestionType.date:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showValidationError)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Please select a date',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.showValidationError
                        ? Colors.red
                        : Colors.grey.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Select a date',
                      style: TextStyle(
                        color:
                            _selectedDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

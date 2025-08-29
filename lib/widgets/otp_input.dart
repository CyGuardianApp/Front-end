import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onComplete;
  final int length;

  const OtpInput({
    super.key,
    required this.controller,
    required this.onComplete,
    this.length = 6,
  });

  @override
  _OtpInputState createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput>
    with SingleTickerProviderStateMixin {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers =
        List.generate(widget.length, (index) => TextEditingController());

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // When the main controller changes, update the individual controllers
    widget.controller.addListener(_updateControllers);
  }

  void _updateControllers() {
    final text = widget.controller.text;
    for (int i = 0; i < widget.length; i++) {
      if (i < text.length) {
        _controllers[i].text = text[i];
      } else {
        _controllers[i].text = '';
      }
    }
  }

  void _updateMainController() {
    final String text =
        _controllers.map((controller) => controller.text).join();
    widget.controller.text = text;

    if (text.length == widget.length) {
      widget.onComplete(text);
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    _animationController.dispose();
    widget.controller.removeListener(_updateControllers);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.length,
            (index) => Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: _buildOtpField(index),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter the 6-character code sent to your email',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpField(int index) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _focusNodes[index].hasFocus ? _scaleAnimation.value : 1.0,
          child: Container(
            width: 36, // Further reduced from 40 to 36
            height: 44, // Further reduced from 48 to 44
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(10), // Further reduced from 12 to 10
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6, // Further reduced from 8 to 6
                  spreadRadius: 0,
                  offset: const Offset(0, 2), // Further reduced from 3 to 2
                ),
              ],
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.text, // Changed from number to text
              textCapitalization:
                  TextCapitalization.characters, // Auto-capitalize letters
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 18, // Further reduced from 20 to 18
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: _focusNodes[index].hasFocus
                    ? Colors.white
                    : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      10), // Further reduced from 12 to 10
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      10), // Further reduced from 12 to 10
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      10), // Further reduced from 12 to 10
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      10), // Further reduced from 12 to 10
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1,
                  ),
                ),
              ),
              inputFormatters: [
                // Allow letters and numbers, no special characters
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              onChanged: (value) {
                if (value.isNotEmpty && index < widget.length - 1) {
                  _focusNodes[index + 1].requestFocus();
                }
                _updateMainController();
              },
              onTap: () {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
              },
            ),
          ),
        );
      },
    );
  }
}

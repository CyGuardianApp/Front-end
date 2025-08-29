import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double small;
  final double medium;
  final double large;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.small = 450,
    this.medium = 800,
    this.large = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth;
        if (constraints.maxWidth > large) {
          maxWidth = large;
        } else if (constraints.maxWidth > medium) {
          maxWidth = medium;
        } else {
          maxWidth = small;
        }

        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

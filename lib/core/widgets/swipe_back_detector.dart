import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SwipeBackDetector extends StatelessWidget {
  final Widget child;

  const SwipeBackDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detect swipe direction: Left to Right (Velocity > 0)
        // Adjust threshold as needed
        if (details.primaryVelocity! > 200) {
          if (context.canPop()) {
            context.pop();
          }
        }
      },
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

class AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;
  final ValueChanged<int> onTabSelect;

  const AnimatedBranchContainer({
    super.key, 
    required this.currentIndex, 
    required this.children,
    required this.onTabSelect,
  });

  @override
  State<AnimatedBranchContainer> createState() => _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  // Animation Definitions
  late Animation<Offset> _slideInAnimation;
  late Animation<Offset> _slideOutAnimation;
  
  // State Tracking
  int _currentIndex = 0; // The tab we are leaving (or current tab)
  int _nextIndex = 0;    // The tab we are going to (during drag/anim)
  


  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _nextIndex = widget.currentIndex;
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
         // Normal transition completed
         _currentIndex = _nextIndex;
         setState(() {});
      }
    });

    // Initialize with safe defaults
    _resetAnimations();
    _controller.value = 1.0; 
  }
  
  void _resetAnimations() {
     _slideInAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_controller);
     _slideOutAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.currentIndex != oldWidget.currentIndex) {
      // If we arrived here and _currentIndex already matches widget.currentIndex, 
      // it implies our interactive transition called setState/onTabSelect and we anticipate this update.
      // However, usually widget.currentIndex updates to the NEW value.
      

      
      // Programmatic Tab Switch (Tap on Bottom Bar)
      _currentIndex = oldWidget.currentIndex;
      _nextIndex = widget.currentIndex;

      
      final bool isPop = (widget.currentIndex == 0);
      
      // Parallax Config
      final Offset enterBegin = isPop ? const Offset(-0.25, 0.0) : const Offset(1.0, 0.0);
      final Offset exitEnd = isPop ? const Offset(1.0, 0.0) : const Offset(-0.25, 0.0);
      
      const curve = Curves.easeOutCubic; 

      _slideInAnimation = Tween<Offset>(begin: enterBegin, end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: curve));
          
      _slideOutAnimation = Tween<Offset>(begin: Offset.zero, end: exitEnd)
          .animate(CurvedAnimation(parent: _controller, curve: curve));

      _controller.forward(from: 0.0);
      // Note: We don't necessarily need setState here because didUpdateWidget implies a rebuild is coming?
      // Actually, didUpdateWidget is called *before* build. So setting state vars is enough.
      // BUT, _controller.forward() starts async. 
      // The build method will see isAnimating=true immediately? 
      // Yes, _controller.forward() sets status to forward immediately.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optimization: Calculate this once per build, not per animation tick
    final int effectiveCurrent = widget.currentIndex;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Animated Content Layer
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
             final bool isTransitioning = _controller.isAnimating;

             return Stack(
              fit: StackFit.expand,
              children: [
                ...widget.children.map((child) {
                  final int index = widget.children.indexOf(child);
                  
                  bool isVisible = false;
                  if (!isTransitioning) {
                     isVisible = (index == effectiveCurrent);
                  } else {
                     isVisible = (index == _currentIndex || index == _nextIndex);
                  }
                  
                  Widget content = child;
                  
                  // Add shadow to non-home pages for depth during transition
                  if (index != 0) {
                    content = DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2), // Depth shadow
                            blurRadius: 20,
                            spreadRadius: -2,
                            offset: const Offset(-5, 0), // Shadow on LEFT edge
                          ),
                        ],
                      ),
                      child: content,
                    );
                  }
                  
                  if (isTransitioning) {
                     if (index == _currentIndex) {
                        content = SlideTransition(position: _slideOutAnimation, child: content);
                     } else if (index == _nextIndex) {
                        content = SlideTransition(position: _slideInAnimation, child: content);
                     }
                  }
                   
                  return Offstage(
                    offstage: !isVisible,
                    child: TickerMode(
                      enabled: isVisible,
                      child: RepaintBoundary(child: content), 
                    ),
                  );
                }),
              ],
            );
          },
        ),

        // 2. Simple Swipe Detector (Triggers Navigation on Swipe, No Laggy Dragging)
        // Active if NOT on Home Screen. 
        if (effectiveCurrent != 0) 
          Positioned(
            left: 0, 
            top: 0, 
            bottom: 0, 
            width: 45, 
            child: GestureDetector(
              behavior: HitTestBehavior.translucent, 
              // We only care about the END of the swipe to trigger the action.
              // We do not update the UI during the drag (preventing "dancing" lag).
              onHorizontalDragEnd: (details) {
                // Check if swipe was "Right" (Positive Velocity)
                if (details.primaryVelocity! > 300) {
                   // Go Back to Home
                   widget.onTabSelect(0);
                }
              },
              child: Container(color: Colors.transparent), 
            ),
          ),
      ],
    );
  }
}

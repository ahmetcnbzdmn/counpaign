import 'package:flutter/material.dart';

class WalletStack extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double cardHeight;
  final ValueChanged<int>? onPageChanged;
  final PageController? controller;

  const WalletStack({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.cardHeight = 220,
    this.onPageChanged,
    this.controller,
  });

  @override
  State<WalletStack> createState() => _WalletStackState();
}

class _WalletStackState extends State<WalletStack> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = widget.controller ?? PageController(viewportFraction: 0.85);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.cardHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.itemCount,
        padEnds: false, // Allows cards to start from left edge if needed, or center
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          if (widget.onPageChanged != null) {
            widget.onPageChanged!(index);
          }
        },
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
              } else {
                 value = (index == _currentPage) ? 1.0 : 0.9;
              }
              
              return Center(
                child: Transform.scale(
                  scale: value,
                  child: widget.itemBuilder(context, index),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

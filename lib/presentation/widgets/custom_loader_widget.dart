import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../../core/utils/common_methods.dart';

class CustomLoaderWidget extends StatefulWidget {
  final double size;
  const CustomLoaderWidget({super.key, this.size = 50.0});

  @override
  State<CustomLoaderWidget> createState() => _CustomLoaderWidgetState();
}

class _CustomLoaderWidgetState extends State<CustomLoaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Standard rotation speed
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensively handle size to avoid CoreGraphics NaN errors (min size 1.0)
    final double safeSize = CommonMethods.safeSize(widget.size, defaultValue: 50.0, min: 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        // Guard against NaN in rotation angle
        final double angle = _controller.value * 2 * math.pi;
        return Transform.rotate(
          angle: angle.isFinite ? angle : 0.0,
          child: child,
        );
      },
      child: SvgPicture.asset(
        'assets/images/loader.svg',
        width: safeSize,
        height: safeSize,
      ),
    );
  }
}

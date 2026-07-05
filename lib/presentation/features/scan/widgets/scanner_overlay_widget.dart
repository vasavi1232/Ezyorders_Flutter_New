import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScannerOverlayWidget extends StatefulWidget {
  const ScannerOverlayWidget({super.key});

  @override
  State<ScannerOverlayWidget> createState() => _ScannerOverlayWidgetState();
}

class _ScannerOverlayWidgetState extends State<ScannerOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScannerOverlayPainter(_controller.value),
          child: Container(),
        );
      },
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double animationValue;

  _ScannerOverlayPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Define Scan Area (Square Cutout)
    final double scanAreaSize = 250.w;
    final Rect scanRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // 2. Draw Background (Darkened with Cutout)
    final Paint backgroundPaint = Paint()..color = Colors.black54;
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 3. Draw Green Corners
    final Paint cornerPaint = Paint()
      ..color = const Color(0xFF00FF00) // Standard Green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    final double cornerLength = 20.w;

    // Top Left
    canvas.drawPath(
        Path()
          ..moveTo(scanRect.left, scanRect.top + cornerLength)
          ..lineTo(scanRect.left, scanRect.top)
          ..lineTo(scanRect.left + cornerLength, scanRect.top),
        cornerPaint);

    // Top Right
    canvas.drawPath(
        Path()
          ..moveTo(scanRect.right - cornerLength, scanRect.top)
          ..lineTo(scanRect.right, scanRect.top)
          ..lineTo(scanRect.right, scanRect.top + cornerLength),
        cornerPaint);

    // Bottom Left
    canvas.drawPath(
        Path()
          ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
          ..lineTo(scanRect.left, scanRect.bottom)
          ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
        cornerPaint);

    // Bottom Right
    canvas.drawPath(
        Path()
          ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
          ..lineTo(scanRect.right, scanRect.bottom)
          ..lineTo(scanRect.right, scanRect.bottom - cornerLength),
        cornerPaint);

    // 4. Draw Red Laser Line (Animated)
    final Paint laserPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double laserY = scanRect.top + (scanRect.height * animationValue);

    // Draw line slightly inside the box
    canvas.drawLine(Offset(scanRect.left + 5.w, laserY),
        Offset(scanRect.right - 5.w, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

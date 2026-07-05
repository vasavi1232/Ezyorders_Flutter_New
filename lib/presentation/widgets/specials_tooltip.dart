import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../../core/utils/common_methods.dart';

enum TooltipArrowDirection { left, bottom }

class SpecialsTooltip {
  static void show(BuildContext context,
      {required String discountId,
      required String discountName,
      Offset? tapPosition,
      Rect? targetRect}) {
    // Setting check: Only show if specific setting is YES
    final dashboardProvider = context.read<DashboardProvider>();
    final showSpecialIdDescription = dashboardProvider
            .profileResponse?.results?.firstOrNull?.showSpecialIdDescription ==
        "Yes";

    if (!showSpecialIdDescription) {
      return;
    }

    // Safety check: Don't show if both fields are empty or blank
    if (discountId.trim().isEmpty && discountName.trim().isEmpty) {
      return;
    }

    // If no tap position and no target rect, use centered dialog
    if (tapPosition == null && targetRect == null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
          child: _buildTooltipBody(discountId, discountName),
        ),
      );
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final screenSize = overlay.context.size ?? MediaQuery.of(context).size;

    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: "Tooltip",
      barrierColor: Colors.black.withValues(alpha: 0.05),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) {
        final tooltipWidth = 240.w;
        final screenWidth = screenSize.width;

        double left;
        double top;
        TooltipArrowDirection direction;
        Offset translation;
        double arrowX;
        final double currentArrowSize = 0.0; // Arrow removed per user request

        if (targetRect != null) {
          // Position ABOVE the target rect with a clear gap
          left = targetRect.center.dx - (tooltipWidth / 2);
          top = targetRect.top - 8.h;
          direction = TooltipArrowDirection.bottom;
          translation = const Offset(0, -1); // Move tooltip body above the point

          // Keep on screen
          if (left < 10.w) left = 10.w;
          if (left + tooltipWidth > screenWidth - 10.w) {
            left = screenWidth - tooltipWidth - 10.w;
          }
          
          arrowX = targetRect.center.dx - left;
        } else {
          // Legacy tap position behavior (LEFT pointing arrow, tooltip to the right)
          double x = tapPosition!.dx;
          double y = tapPosition.dy;
          left = x + currentArrowSize;
          direction = TooltipArrowDirection.left;
          translation = const Offset(0, -0.5);

          if (left + tooltipWidth > screenWidth - 10.w) {
            left = x - tooltipWidth - currentArrowSize;
          }
          if (left < 10.w) left = 10.w;
          top = y;
          arrowX = currentArrowSize;
        }

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: FractionalTranslation(
                translation: translation,
                child: FadeTransition(
                  opacity: animation,
                  child: Material(
                    color: Colors.transparent,
                    child: _TooltipWithArrow(
                      discountId: discountId,
                      discountName: discountName,
                      tooltipWidth: tooltipWidth,
                      arrowSize: currentArrowSize,
                      direction: direction,
                      arrowX: arrowX,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the tooltip body with two-tone background
  static Widget _buildTooltipBody(String discountId, String discountName) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFBFC5D2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.r),
        child: _buildSections(discountId, discountName),
      ),
    );
  }

  static Widget _buildSections(String discountId, String discountName) {
    final String cleanId = CommonMethods.decodeHtmlEntities(discountId);
    final String cleanName = CommonMethods.decodeHtmlEntities(discountName);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFFD6DCE8),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Text(
            cleanId,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (cleanName.isNotEmpty)
          Container(
            color: const Color(0xFFF2F2F2),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Text(
              cleanName,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _TooltipWithArrow extends StatelessWidget {
  final String discountId;
  final String discountName;
  final double tooltipWidth;
  final double arrowSize;
  final TooltipArrowDirection direction;
  final double arrowX;

  const _TooltipWithArrow({
    required this.discountId,
    required this.discountName,
    required this.tooltipWidth,
    required this.arrowSize,
    required this.direction,
    required this.arrowX,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: (direction == TooltipArrowDirection.left)
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.end,
          children: [
            if (direction == TooltipArrowDirection.left && arrowSize > 0)
              _buildArrow(),
            
            // Tooltip Body
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: tooltipWidth),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFBFC5D2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7.r),
                  child: SpecialsTooltip._buildSections(discountId, discountName),
                ),
              ),
            ),
          ],
        ),
        if (direction == TooltipArrowDirection.bottom && arrowSize > 0)
          _buildArrow(),
      ],
    );
  }

  Widget _buildArrow() {
    return CustomPaint(
      size: (direction == TooltipArrowDirection.left)
          ? Size(arrowSize, arrowSize * 1.5)
          : Size(tooltipWidth, arrowSize),
      painter: _TooltipPainter(
        arrowSize: arrowSize,
        direction: direction,
        arrowX: arrowX,
      ),
    );
  }
}

class _TooltipPainter extends CustomPainter {
  final double arrowSize;
  final TooltipArrowDirection direction;
  final double arrowX;

  _TooltipPainter({
    required this.arrowSize,
    required this.direction,
    required this.arrowX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFBFC5D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Path path = Path();

    if (direction == TooltipArrowDirection.left) {
      final centerY = size.height / 2;
      final fillPaint = Paint()
        ..color = const Color(0xFFDDE1EB) // Blend color
        ..style = PaintingStyle.fill;

      path.moveTo(0, centerY);
      path.lineTo(size.width, centerY - arrowSize);
      path.lineTo(size.width, centerY + arrowSize);
      path.close();

      canvas.drawPath(path, fillPaint);
      
      final bPath = Path();
      bPath.moveTo(size.width, centerY - arrowSize);
      bPath.lineTo(0, centerY);
      bPath.lineTo(size.width, centerY + arrowSize);
      canvas.drawPath(bPath, borderPaint);
      
    } else if (direction == TooltipArrowDirection.bottom) {
      // Clamp arrowX to avoid drawing arrow outside tooltip body
      final double tipX = arrowX.clamp(arrowSize, size.width - arrowSize);
      
      final fillPaint = Paint()
        ..color = const Color(0xFFF2F2F2) // Bottom section color
        ..style = PaintingStyle.fill;

      path.moveTo(tipX, size.height); // Tip
      path.lineTo(tipX - arrowSize, 0); // Top left
      path.lineTo(tipX + arrowSize, 0); // Top right
      path.close();

      canvas.drawPath(path, fillPaint);

      final bPath = Path();
      bPath.moveTo(tipX - arrowSize, 0);
      bPath.lineTo(tipX, size.height);
      bPath.lineTo(tipX + arrowSize, 0);
      canvas.drawPath(bPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

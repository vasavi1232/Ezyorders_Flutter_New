import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/common_methods.dart';

class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String orderId;
  final String content;
  final String confirmText;
  final Color confirmColor;
  final Color? confirmButtonColor;

  const CustomConfirmDialog({
    super.key,
    required this.title,
    required this.orderId,
    required this.content,
    required this.confirmText,
    required this.confirmColor,
    this.confirmButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(horizontal: CommonMethods.safeSize(24.w)),
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              color: confirmColor, // The bright orange from screenshot
              padding: EdgeInsets.symmetric(
                  horizontal: CommonMethods.safeSize(16.w), 
                  vertical: CommonMethods.safeSize(12.h)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: CommonMethods.safeSize(16.sp, defaultValue: 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Icon(Icons.close, color: Colors.white, 
                        size: CommonMethods.safeSize(24.sp, defaultValue: 24)),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: EdgeInsets.only(
                  top: CommonMethods.safeSize(24.h), 
                  left: CommonMethods.safeSize(16.w), 
                  right: CommonMethods.safeSize(16.w), 
                  bottom: CommonMethods.safeSize(24.h)),
              child: Column(
                children: [
                  Text(
                    orderId,
                    style: TextStyle(
                      color: const Color(0xFF283593), // Dark Blue for Order ID
                      fontSize: CommonMethods.safeSize(18.sp, defaultValue: 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: CommonMethods.safeSize(12.h)),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: CommonMethods.safeSize(14.sp, defaultValue: 14),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: EdgeInsets.only(
                  left: CommonMethods.safeSize(16.w), 
                  right: CommonMethods.safeSize(16.w), 
                  bottom: CommonMethods.safeSize(20.h)),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmButtonColor ?? confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
                        padding: EdgeInsets.symmetric(vertical: CommonMethods.safeSize(12.h)),
                      ),
                      child: Text(
                        confirmText,
                        style: TextStyle(
                            fontSize: CommonMethods.safeSize(14.sp, defaultValue: 14), 
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: CommonMethods.safeSize(12.w)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
                        padding: EdgeInsets.symmetric(vertical: CommonMethods.safeSize(12.h)),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                            fontSize: CommonMethods.safeSize(14.sp, defaultValue: 14), 
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

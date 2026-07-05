import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../config/theme/app_theme.dart';

class CustomSuccessDialog extends StatelessWidget {
  final String title;
  final String orderId;
  final String content;
  final VoidCallback? onOk;

  const CustomSuccessDialog({
    super.key,
    required this.title,
    required this.orderId,
    required this.content,
    this.onOk,
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
              color: AppTheme.primaryButtonColor,
              padding: EdgeInsets.symmetric(
                  horizontal: CommonMethods.safeSize(16.w), 
                  vertical: CommonMethods.safeSize(12.h)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Orders", // Native screenshot shows "My Orders" in the header
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: CommonMethods.safeSize(16.sp, defaultValue: 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  bottom: CommonMethods.safeSize(20.h)),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: CommonMethods.safeSize(14.sp, defaultValue: 14),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: CommonMethods.safeSize(4.h)),
                  Text(
                    "Order ID : $orderId",
                    style: TextStyle(
                      color: const Color(0xFF283593), // Dark Blue for Order ID
                      fontSize: CommonMethods.safeSize(15.sp, defaultValue: 15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Button
            Padding(
              padding: EdgeInsets.only(bottom: CommonMethods.safeSize(24.h)),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onOk != null) onOk!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryButtonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CommonMethods.safeSize(4.r, defaultValue: 4))),
                  padding:
                      EdgeInsets.symmetric(
                          horizontal: CommonMethods.safeSize(40.w), 
                          vertical: CommonMethods.safeSize(10.h)),
                ),
                child: Text(
                  "Ok",
                  style:
                      TextStyle(
                          fontSize: CommonMethods.safeSize(14.sp, defaultValue: 14), 
                          fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';

class ClearCartDialog extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onClose;

  const ClearCartDialog({
    super.key,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppTheme.redColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5.r),
                topRight: Radius.circular(5.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Clear Cart Confirmation",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: Icon(Icons.close, color: Colors.white, size: 20.sp),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
            child: Text(
              "Are you sure to clear items in the cart?",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Footer Buttons
          Padding(
            padding: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clear Cart Button
                Expanded(
                  child: SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      onPressed: onClear,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.redColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Clear Cart",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                // Close Button
                Expanded(
                  child: SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

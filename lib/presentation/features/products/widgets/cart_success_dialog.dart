import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';

class CartSuccessDialog extends StatefulWidget {
  final String productName;
  final bool isUpdate;

  const CartSuccessDialog({
    super.key,
    required this.productName,
    this.isUpdate = false,
  });

  @override
  State<CartSuccessDialog> createState() => _CartSuccessDialogState();
}

class _CartSuccessDialogState extends State<CartSuccessDialog> {
  Timer? _timer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDismissed) {
        _isDismissed = true;
        Navigator.of(context).pop();
      }
    });
  }

  void _dismissDialog() {
    if (!_isDismissed && mounted) {
      _isDismissed = true;
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletLandscape =
        MediaQuery.of(context).size.shortestSide >= 600 &&
            MediaQuery.of(context).orientation == Orientation.landscape;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Primary / Secondary color matching orange in screenshot
          Container(
            color: AppTheme.tealColor,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add To Cart",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _dismissDialog,
                  child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: EdgeInsets.only(
                top: 40.h, left: 16.w, right: 16.w, bottom: 20.h),
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: widget.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: widget.isUpdate
                            ? " cart quantity updated successfully"
                            : " added to cart successfully",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),

                // Close Button
                SizedBox(
                  width: isTabletLandscape ? 150.w : 100.w,
                  height: isTabletLandscape ? 50.h : null,
                  child: ElevatedButton(
                    onPressed: _dismissDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryButtonColor, // Secondary
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: isTabletLandscape
                          ? EdgeInsets.zero
                          : EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/utils/common_methods.dart';

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
    if (!_isDismissed) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.tealColor, // Orange
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  topRight: Radius.circular(10.r),
                ),
              ),
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
                  InkWell(
                    onTap: _dismissDialog,
                    child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: CommonMethods.decodeHtmlEntities(widget.productName),
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
            ),

            // Footer Button
            Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: SizedBox(
                width: isTabletLandscape ? 150.w : 120.w,
                height: isTabletLandscape ? 55.h : 40.h,
                child: ElevatedButton(
                  onPressed: _dismissDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryButtonColor, // Secondary
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
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

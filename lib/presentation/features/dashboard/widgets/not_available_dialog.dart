import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/utils/common_methods.dart';

class NotAvailableDialog extends StatelessWidget {
  final String supplierName;
  final String description;

  const NotAvailableDialog({
    super.key,
    required this.supplierName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.r), // Standardizing to match Android
      ),
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0.r), // Square corners like native UI provided
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (Red Background for Not Available)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.redColor,
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
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
              child: Column(
                children: [
                  // Supplier Name
                  Text(
                    CommonMethods.decodeHtmlEntities(supplierName),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // Description (often HTML formatted indicating availability times)
                  Html(
                    data: description.replaceAll('</div>', '</div><br>').trim(),
                    style: {
                      "body": Style(
                        textAlign: TextAlign.center,
                        fontSize: FontSize(14.sp),
                        color: AppTheme.textColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                    },
                  ),
                ],
              ),
            ),

            // Footer Button
            Padding(
              padding: EdgeInsets.only(bottom: 25.h),
              child: Center(
                child: SizedBox(
                  width: 120.w,
                  height: 40.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
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
            ),
          ],
        ),
      ),
    );
  }
}

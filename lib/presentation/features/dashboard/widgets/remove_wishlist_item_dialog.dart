import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/home_models.dart';
import '../../../../core/utils/common_methods.dart';

class RemoveWishlistItemDialog extends StatelessWidget {
  final ProductItem item;
  final String? categoryName;
  final VoidCallback onDelete;

  const RemoveWishlistItemDialog({
    super.key,
    required this.item,
    this.categoryName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            color: AppTheme.redColor,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Delete From Wishlist",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.white, size: 28.sp),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
            child: Column(
              children: [
                Text(
                  CommonMethods.decodeHtmlEntities(item.title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (categoryName != null && categoryName!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      "[$categoryName]",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                SizedBox(height: 10.h),
                Text(
                  "Are you sure to delete this Product from Wishlist?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 30.h),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Delete Button
                    SizedBox(
                      width: 110.w,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryButtonColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        child: Text(
                          "Delete",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15.w),
                    // Close Button
                    SizedBox(
                      width: 110.w,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryButtonColor,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        child: Text(
                          "Close",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color : Colors.white
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

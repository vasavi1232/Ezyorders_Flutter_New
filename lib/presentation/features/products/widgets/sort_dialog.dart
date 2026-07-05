import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../providers/product_list_provider.dart';

class SortDialog extends StatelessWidget {
  const SortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductListProvider>(
      builder: (context, provider, child) {
        final options = provider.sortList;
        final selectedValue = CommonMethods.sortIDs;

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          child: Container(
            padding: EdgeInsets.zero,
            width: 300.w, // Ensure dialog has width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppTheme.tealColor, // Teal/Orange color
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.r),
                      topRight: Radius.circular(8.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sort By",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child:
                            Icon(Icons.close, color: Colors.white, size: 24.w),
                      ),
                    ],
                  ),
                ),

                // Content
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1.h, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == selectedValue;

                      return InkWell(
                        onTap: () {
                          provider.onSortSelected(option);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 12.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  option.name ?? "",
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.black,
                                    fontSize: 14.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: AppTheme.primaryColor, size: 20.w)
                              else
                                Icon(Icons.radio_button_off,
                                    color: Colors.grey, size: 20.w),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

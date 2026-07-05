import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onPrevTap;
  final VoidCallback? onNextTap;
  final bool showNavButtons;
  final int? itemCount;
  final int minItemsForNav;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    this.onPrevTap,
    this.onNextTap,
    this.showNavButtons = true,
    this.itemCount,
    this.minItemsForNav = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.0.w, right: 8.0.w, top: 10.0.h, bottom: 10.0.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF333333),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (showNavButtons && (itemCount == null || itemCount! >= minItemsForNav))
            Row(
              children: [
                _buildNavButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: onPrevTap,
                  isActive: onPrevTap != null,
                ),
                SizedBox(width: 12.w),
                _buildNavButton(
                  icon: Icons.arrow_forward_ios,
                  onTap: onNextTap,
                  isActive: onNextTap != null,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.productButtonRadius.r),
      child: Container(
        width: AppTheme.arrowSize.w,
        height: AppTheme.arrowSize.w,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.tealColor : AppTheme.tealColor.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

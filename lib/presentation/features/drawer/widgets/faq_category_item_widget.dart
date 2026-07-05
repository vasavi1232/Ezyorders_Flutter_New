import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:html/parser.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../data/models/drawer_models.dart';

class FAQCategoryItemWidget extends StatelessWidget {
  final FAQCategory item;
  final VoidCallback onTap;

  const FAQCategoryItemWidget(
      {super.key, required this.item, required this.onTap});

  String _parseHtmlString(String htmlString) {
    if (htmlString.isEmpty) return "";
    final document = parse(htmlString);
    return document.body?.text ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppTheme.appbarColor,
        margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
        child: Padding(
          padding: EdgeInsets.all(15.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _parseHtmlString(item.categoryName ?? ""),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

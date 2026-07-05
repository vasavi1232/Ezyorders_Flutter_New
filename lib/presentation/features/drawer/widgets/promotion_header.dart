import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../widgets/custom_loader_widget.dart';

class PromotionHeader extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String dateRange;

  const PromotionHeader(
      {super.key,
      required this.imageUrl,
      required this.title,
      required this.dateRange});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0.r),
                      topRight: Radius.circular(0.r),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!.contains("http")
                          ? imageUrl!
                          : "${UrlApiKey.mainUrl}$imageUrl",
                      width: double.infinity,
                      height: 120.h,
                      fit: BoxFit.fill,
                      placeholder: (context, url) =>
                          Center(child: CustomLoaderWidget(size: 30.w)),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                // Tag Overlay
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.tealColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text("Promotion",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            // Title and Date Column
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CommonMethods.decodeHtmlEntities(title),
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B3E8F)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    dateRange,
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[700]!,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}

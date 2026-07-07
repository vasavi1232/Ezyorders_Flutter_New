import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/network/image_cache_manager.dart';
import '../../../../core/utils/common_methods.dart';

class HomePromotionItemWidget extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double width;
  final bool showShopNow;

  const HomePromotionItemWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.width,
    this.showShopNow = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      width: width,
      margin: EdgeInsets.only(bottom: 5.h),
      padding:
          EdgeInsets.only(bottom: 5.h), // Extra padding for shadow/elevation
      child: Card(
        elevation: 2,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(5.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Section
                SizedBox(
                  height: isLandscape ? 160.h : 120.h, // Increased in landscape
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildImage(imageUrl)),
                    ],
                  ),
                ),
                SizedBox(height: 5.h),

                // Title
                Text(
                  CommonMethods.decodeHtmlEntities(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                  ),
                ),

                // Subtitle (Date or Count)
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.darkGrayColor,
                      fontWeight:  FontWeight.w800,),
                ),

                // Shop Now Section
                if (showShopNow) ...[
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Shop Now",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(Icons.arrow_forward_ios,
                          color: AppTheme.primaryColor, size: 12.sp),
                    ],
                  ),
                  SizedBox(height: 4.h), 
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(color: Colors.grey[200]);
    }
    String finalUrl = path;
    if (!path.startsWith("http")) {
      finalUrl = "${UrlApiKey.mainUrl}$path";
    }

    return CachedNetworkImage(
      imageUrl: finalUrl,
      fit: BoxFit.fill, // fitXY
      cacheManager: ImageCacheManager(),
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

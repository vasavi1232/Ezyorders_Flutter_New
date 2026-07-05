import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/utils/common_methods.dart';

import '../../../../data/models/drawer_models.dart';

class NotificationItemWidget extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItemWidget({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String imageUrl = item.image ?? "";
    if (imageUrl.isNotEmpty && !imageUrl.startsWith("http")) {
      imageUrl = "${UrlApiKey.mainUrl}$imageUrl";
    }

    bool hasImage = CommonMethods.hasValidImage(imageUrl);
    // Default to showing image BEFORE text unless specifically set to "After Message"
    bool isBeforeImage = !(item.imagePosition?.toLowerCase().trim().contains("after") ?? false);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.only(bottom: 10.h),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Before
                    if (hasImage && isBeforeImage)
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 200.w, // Matches Android dimen_200
                              height: 100.w, // Matches Android dimen_100
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.broken_image, size: 40.w),
                            ),
                          ),
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title ?? "",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue, // Matches Android @color/blue
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      item.description ?? "",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                      maxLines: 3, // Matches Android lines="3"
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Image After
                    if (hasImage && !isBeforeImage)
                      Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 200.w, // Matches Android dimen_200
                              height: 100.w, // Matches Android dimen_100
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.broken_image, size: 40.w),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Right side actions: New Tag and Delete Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.status == "UnRead")
                    Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        "New",
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ),
                  InkWell(
                    onTap: onDelete,
                    child: Padding(
                      padding: EdgeInsets.all(5.w),
                      child: Icon(Icons.delete, color: Colors.red, size: 20.sp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

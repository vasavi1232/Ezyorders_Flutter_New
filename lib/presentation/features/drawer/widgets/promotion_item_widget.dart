import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/drawer_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../providers/product_list_provider.dart';
import 'promotion_header.dart';
import '../../../widgets/custom_loader_widget.dart';

class PromotionItemWidget extends StatelessWidget {
  final PromotionsItem item;
  final int index;
  final double? itemHeight;

  const PromotionItemWidget(
      {super.key, required this.item, required this.index, this.itemHeight});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr);
      const List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = item.image ?? "";
    if (!imageUrl.startsWith("http")) {
      imageUrl = "${UrlApiKey.mainUrl}$imageUrl";
    }

    return GestureDetector(
      onTap: () {
        final productProvider = context.read<ProductListProvider>();
        productProvider.clearFilters();

        CommonMethods.productsBack = "Banners";
        bool hasDivision = item.divisionId != null &&
            item.divisionId != "0" &&
            item.divisionId!.isNotEmpty;
        bool hasGroup = item.groupId != null &&
            item.groupId != "0" &&
            item.groupId!.isNotEmpty;

        if (hasDivision) {
          CommonMethods.categoryIDs = item.divisionId!;
          CommonMethods.firstCatIds = item.divisionId!;
        }

        if (hasGroup) {
          CommonMethods.groupIDs = item.groupId!;
          CommonMethods.firstGroupids = item.groupId!;
        }

        if (item.subGroupId != null &&
            item.subGroupId != "0" &&
            item.subGroupId!.isNotEmpty) {
          CommonMethods.subGroupIDs = item.subGroupId!;
          CommonMethods.firstSubGroupids = item.subGroupId!;
        }

        if (item.subSubGroupId != null &&
            item.subSubGroupId != "0" &&
            item.subSubGroupId!.isNotEmpty) {
          CommonMethods.subSubGroupIDs = item.subSubGroupId!;
          // CommonMethods.firstSubSubGroupids = item.subSubGroupId!; // Note: CommonMethods seems to miss this 'first' variable but we set the active one
        }

        if (item.products != null && item.products!.isNotEmpty) {
          final productIds = item.products!
              .map((p) => p.productId)
              .whereType<String>()
              .join(',');
          CommonMethods.selecetedProducts = productIds;
          CommonMethods.firstSelProds = productIds;
        }

        context.push(
          AppRoutes.productsList,
          extra: {
            'pageTitle': "Promotions",
            'headerWidget': PromotionHeader(
              imageUrl: item.image,
              title: item.displayName ?? "",
              dateRange:
                  "${_formatDate(item.fromDate)} - ${_formatDate(item.toDate)}",
            ),
          },
        );
      },
      child: SizedBox(
        // Each card takes exactly 1/3 of available body height (minus margin)
        height: itemHeight != null ? itemHeight! - 10.h : null,
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.only(bottom: 10.h),
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.r)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image fills all space not used by the text section
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(5.r)),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Center(child: CustomLoaderWidget(size: 30.w)),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10.h,
                      left: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppTheme.tealColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "Promotion",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Fixed text section: title + date
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CommonMethods.decodeHtmlEntities(
                          item.displayName ?? ""),
                      style: TextStyle(
                        fontSize: 15.sp, // Increased from 13.sp
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Sharp contrast on white
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.fromDate != null && item.toDate != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        "${_formatDate(item.fromDate)} - ${_formatDate(item.toDate)}",
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.darkGrayColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

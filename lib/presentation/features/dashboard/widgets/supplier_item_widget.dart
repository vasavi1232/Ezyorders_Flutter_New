import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezy_orders_flutter/core/constants/app_theme.dart';
import 'package:ezy_orders_flutter/core/constants/url_api_key.dart';
import '../../../widgets/custom_loader_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../providers/product_list_provider.dart';

class SupplierItemWidget extends StatelessWidget {
  final String? image;
  final String? brandName;
  final String? brandId;
  final double? width;

  const SupplierItemWidget({
    super.key,
    this.image,
    this.brandName,
    this.brandId,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Use passed width or fall back to screen-based calculation.
    double itemWidth = width ?? (1.sw - 22.w) / 2;

    return GestureDetector(
        onTap: () {
          // Navigate to Products List with supplier filter
          if (brandId != null) {
            final productProvider = context.read<ProductListProvider>();
            productProvider.clearFilters();
            productProvider.setSupplier(brandId!);

            // context.read<DashboardProvider>().setIndex(1);

            context.push(AppRoutes.productsList, extra: {
              'supplierId': brandId,
              'backNav': 'suppliers',
              'pageTitle': brandName ?? "Products"
            });
          }
        },
        child: Container(
          width: itemWidth,
          margin: EdgeInsets.only(
            bottom: 6.h,
          ),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowBlack,
                offset: const Offset(0, 6), // 👈 shadow goes DOWN
                blurRadius: 8,
                spreadRadius: -2, // 👈 prevents side shadow
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 90.h,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  border: Border.all(
                    color: AppTheme.darkGrayColor,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(1.r),
                ),
                padding: EdgeInsets.all(1.5.w),
                child: _buildImage(image),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                    child: Text(
                      CommonMethods.decodeHtmlEntities(brandName),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(color: AppTheme.lightGrayBg, height: 120.h);
    }
    String finalUrl = path;
    if (!path.startsWith("http")) {
      finalUrl = "${UrlApiKey.mainUrl}$path";
    }

    return CachedNetworkImage(
      imageUrl: finalUrl,
      height: 90.h, // reduced for compact look
      width: double.infinity,
      fit: BoxFit.contain, // Prevent stretching, maintain aspect ratio
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 20.w,
          height: 20.w,
          child: Center(child: CustomLoaderWidget(size: 30.w)),
        ),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error, size: 24.sp),
    );
  }
}

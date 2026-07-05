import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/network/image_cache_manager.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/home_models.dart';
import '../../../../presentation/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';
import '../../products/product_details_screen.dart';

import 'not_available_dialog.dart';

class ProductItemWidget extends StatelessWidget {
  final ProductItem item;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onFavorite;

  const ProductItemWidget({
    super.key,
    required this.item,
    required this.width,
    this.onTap,
    this.onAddToCart,
    this.onFavorite,
    this.badgeLabel,
  });

  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    // Logic from FutureProductsAdapter.kt

    // Sold As Logic
    // TODO: Need access to DashboardProvider or passing 'show_sold_as' flag.
    // For now assuming show_sold_as is false or handled elsewhere, or I can check item fields if they exist.
    // Android checks DashboardViewModel.getUpResponse?.value?.results?.get(0)?.show_sold_as == "Yes"

    final bool isOutOfStock = item.qtyStatus == "Out Of Stock";
    final bool canAddToCart = item.supplierAvailable == "1" &&
        item.productAvailable == "1" &&
        !isOutOfStock;
    final bool hasPromotion = item.hasPromotion == "Yes" &&
        item.promotionPrice != null &&
        double.tryParse(item.promotionPrice ?? "0")! > 0;

    // Vendor Visibility:
    // Android: if category is Promotions/Pop Cat -> GONE.
    // But this widget is mostly for standard products. Passing visibility might be cleaner, but let's default to visible.

    return Container(
      width: width,
      margin: EdgeInsets.only(bottom: 5.h),
      child: Card(
        elevation: 1,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.r), // 👈 decrease radius here
        ),
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailsScreen(productId: item.productId!),
                  ),
                );
              },
          child: Padding(
            padding: EdgeInsets.all(5.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit Header (Orange Bar)
                Consumer<DashboardProvider>(
                  builder: (context, dashboard, child) {
                    final bool showSoldAs =
                        dashboard.profileResponse?.results?[0]?.showSoldAs ==
                            "Yes";
                    if (!showSoldAs) return const SizedBox.shrink();

                    if (item.soldAs != null &&
                        item.soldAs!.isNotEmpty &&
                        item.soldAs != "Each" &&
                        item.qtyPerOuter != null) {
                      return Container(
                        width: double.infinity,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppTheme
                              .tealColor, // Synchronized with tealcolor (Orange)
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${item.soldAs} (${item.qtyPerOuter} Units)",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800),
                        ),
                      );
                    } else if (item.soldAs == "Each") {
                      return Container(
                        width: double.infinity,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppTheme.tealColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Each",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Image Layer
                SizedBox(height: 4.h,),
                Stack(
                  children: [
                    Container(
                      height: 100.h,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: _buildImage(item.image),
                    ),
                    // Status Badge (Top Left)
                    if (badgeLabel != null && badgeLabel!.isNotEmpty)
                      Positioned(
                        top: 6.h,
                        left: 2.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.redColor,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            badgeLabel!,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 5.h),

                // Vendor Name
                if (item.brandName != null && item.brandName!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      item.brandName!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                // Product Name
                SizedBox(height: 2.h),
                Text(
                  CommonMethods.decodeHtmlEntities(
                      item.title ?? item.brandName ?? ""),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800),
                ),

                // MOQ
                if (item.minimumOrderQty != null &&
                    item.minimumOrderQty != "0" &&
                    item.minimumOrderQty != "1")
                  Padding(
                    padding: EdgeInsets.only(top: 5.h),
                    child: Text(
                      "MOQ : ${item.minimumOrderQty}",
                      style: TextStyle(
                          color: AppTheme.redColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                SizedBox(height: 5.h),

                // Price Section
                if (!hasPromotion) ...[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatPrice(item.price),
                      style:
                          TextStyle(color: const Color(0xFF333333), fontSize: 12.sp,fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  // Promotion UI
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          _formatPrice(item.price),
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough),
                        ),
                        SizedBox(width: 5.w),
                        Row(
                          children: [
                            Text(
                              _formatPrice(item.promotionPrice),
                              style: TextStyle(
                                  color: AppTheme.redColor, fontSize: 12.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 5.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 2.h),
                              color: AppTheme.redColor,
                              child: Text(
                                "-${CommonMethods.calculateDiscount(item.price, item.promotionPrice)}%",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],

                // Stock Status
                if (item.stockUnlimited != "Yes")
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Builder(builder: (context) {
                      String stockText = "Out of Stock";
                      if (item.qtyStatus == "Low In Stock") {
                        stockText = "Low In Stock";
                      } else if (item.availableStockQty != null && item.qtyStatus != "Out Of Stock") {
                        stockText = "In Stock : ${item.availableStockQty}";
                      }
                      return Text(
                        stockText,
                        style: TextStyle(
                          color: AppTheme.redColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),

                SizedBox(height: 10.h),

                // Add To Cart & Fav
                //SizedBox(height: 8.h),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: isOutOfStock
                            ? null
                            : (canAddToCart
                                ? onAddToCart
                                : () {
                                    final supplierName = item.supplierAvailable == "0"
                                        ? (item.brandName ?? item.title ?? "")
                                        : (item.name ?? item.title ?? "");
                                    
                                    showDialog(
                                      context: context,
                                      builder: (context) => NotAvailableDialog(
                                        supplierName: supplierName,
                                        description: item.notAvailableDaysMessage ?? "",
                                      ),
                                    );
                                  }),
                        child: Container(
                          height: 35
                              .h, // Adjusted from 40.h to match Android @dimen/dimen_35
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: canAddToCart
                                ? AppTheme.primaryButtonColor
                                : AppTheme.redColor,
                            borderRadius: BorderRadius.circular(AppTheme
                                .productButtonRadius.r), // Standardized radius
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20.w), // Increased internal padding for responsiveness
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isOutOfStock
                                    ? "Out Of Stock"
                                    : (item.addedToCart == "Yes"
                                        ? "Update Cart [${item.addedQty ?? '1'}]"
                                        : "Add To Cart"),
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Consumer<DashboardProvider>(
                      builder: (context, dashboard, child) {
                        final bool showWishlist = dashboard.profileResponse?.results?[0]
                                ?.allowCustomersToAddWishlist ==
                            "Yes";
                        if (!showWishlist) return const SizedBox.shrink();

                        return InkWell(
                          onTap: onFavorite,
                          child: Image.asset(
                            item.isFavourite == "Yes"
                                ? "assets/images/favadded.png"
                                : "assets/images/fav_new.png",
                            width: 30.h,
                            height: 30.h,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 5.h),

                // Shop Now (Hidden by default in FutureProducts except Pop Categories?)
                // Assuming this generic widget is for products.
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(String? price) {
    return CommonMethods.setPriceFormatString(price);
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
      height: 120.h,
      fit: BoxFit.contain, // scaleType="fitCenter"
      cacheManager: ImageCacheManager(),
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

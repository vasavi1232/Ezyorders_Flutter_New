import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/network/image_cache_manager.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/home_models.dart';
import '../../../providers/dashboard_provider.dart';
import '../../products/product_details_screen.dart';

class WishlistItemWidget extends StatelessWidget {
  final ProductItem item;
  final VoidCallback? onAddToCart;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;
  final double? width;
  final bool isSelected;
  final String? categoryName;
  final int? selectedQuantity;
  final VoidCallback? onIncrementQuantity;
  final VoidCallback? onDecrementQuantity;

  const WishlistItemWidget({
    super.key,
    required this.item,
    this.onAddToCart,
    this.onDelete,
    this.onTap,
    this.onSelect,
    this.width,
    this.isSelected = false,
    this.categoryName,
    this.selectedQuantity,
    this.onIncrementQuantity,
    this.onDecrementQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    final bool isOutOfStock = item.qtyStatus == "Out Of Stock";
    final bool canAddToCart = item.supplierAvailable == "1" &&
        item.productAvailable == "1" &&
        !isOutOfStock;
    final bool hasPromotion = item.hasPromotion == "Yes" &&
        item.promotionPrice != null &&
        double.tryParse(item.promotionPrice ?? "0")! > 0;

    return Container(
      width: width,
      margin:
          EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), // List spacing
      child: Card(
        elevation: 1,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.r),
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
            padding: EdgeInsets.all(8.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Checkbox
                    SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: isOutOfStock
                            ? null
                            : (val) {
                                if (onSelect != null) onSelect!();
                              },
                        activeColor: AppTheme.tealColor,
                        side: BorderSide(
                            color: isOutOfStock
                                ? Colors.grey.withValues(alpha: 0.4)
                                : Colors.grey,
                            width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // 2. Image
                    Stack(
                      children: [
                        Container(
                          height: isLandscape ? 60.h : 80.h,
                          width: 80.w,
                          alignment: Alignment.center,
                          child: _buildImage(item.image),
                        ),
                        if (item.label != null && item.label!.isNotEmpty)
                          Positioned(
                            top: 2.h,
                            left: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppTheme.redColor,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: Text(
                                item.label!,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 10.w),

                    // 3. Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSoldAsBar(),
                          Text(
                            CommonMethods.decodeHtmlEntities(item.brandName),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppTheme.darkerGrayColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            CommonMethods.decodeHtmlEntities(item.title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          _buildMOQ(),
                          SizedBox(height: 5.h),
                          // Price Section
                          if (!hasPromotion) ...[
                            Text(
                              _formatPrice(item.price),
                              style: TextStyle(
                                  color: AppTheme.darkerGrayColor,
                                  fontSize: 14.sp),
                            ),
                          ] else ...[
                            // Formatting for promo
                            Text(
                              _formatPrice(item.promotionPrice),
                              style: TextStyle(
                                  color: AppTheme.darkerGrayColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Text(
                                  _formatPrice(item.price),
                                  style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      decorationThickness: 1.5,
                                      decoration: TextDecoration.lineThrough),
                                ),
                                SizedBox(width: 5.w),
                                Builder(
                                  builder: (context) {
                                    String discountStr = "";
                                      discountStr =
                                          "-${CommonMethods.calculateDiscount(item.price, item.promotionPrice)}%";
                                    if (discountStr.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 4.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: AppTheme.redColor,
                                        borderRadius:
                                            BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        discountStr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          ],
                          _buildStockStatus(),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // Bottom Row: Action and Heart Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Side: Add to Cart button OR Quantity Editing Layout
                    Expanded(
                      child: isSelected
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Quantity Controls
                                Container(
                                  height: isLandscape ? 45.h : 35.h,
                                  width: 110.w,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(4.r),
                                    color: AppTheme.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: onDecrementQuantity,
                                        child: Container(
                                          width: 30.w,
                                          alignment: Alignment.center,
                                          child: Text(
                                            "-",
                                            style: TextStyle(
                                              fontSize: 22.sp,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                      VerticalDivider(
                                        width: 1,
                                        thickness: 1,
                                        color: AppTheme.hintColor,
                                      ),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${selectedQuantity ?? 1}",
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                      VerticalDivider(
                                        width: 1,
                                        thickness: 1,
                                        color: AppTheme.hintColor,
                                      ),
                                      InkWell(
                                        onTap: onIncrementQuantity,
                                        child: Container(
                                          width: 30.w,
                                          alignment: Alignment.center,
                                          child: Text(
                                            "+",
                                            style: TextStyle(
                                              fontSize: 22.sp,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Sub Total
                                Row(
                                  children: [
                                    Text(
                                      "Sub Total : ",
                                      style: TextStyle(
                                        color: AppTheme.blackColor,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        double basePrice = double.tryParse(item.price ?? "0") ?? 0.0;
                                        if (item.hasPromotion == "Yes" && item.promotionPrice != null) {
                                          basePrice = double.tryParse(item.promotionPrice!) ?? basePrice;
                                        }
                                        double subtotal = basePrice * (selectedQuantity ?? 1);
                                        return Text(
                                          _formatPrice(subtotal.toString()),
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontSize: 13.sp,
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                )
                              ],
                            )
                          : Row(
                              children: [
                                // Button
                                InkWell(
                                  onTap: canAddToCart ? onAddToCart : null,
                                  child: Container(
                                    height: isLandscape ? 45.h : 32.h,
                                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: canAddToCart
                                            ? AppTheme.primaryButtonColor
                                            : AppTheme.redColor,
                                        borderRadius: BorderRadius.circular(20.r),
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppTheme.shadowBlack,
                                              blurRadius: 4,
                                              offset: Offset(0, 2))
                                        ]),
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
                              ],
                            ),
                    ),

                    SizedBox(width: 10.w),

                    // Right Side: Heart Red Icon
                    InkWell(
                      onTap: onDelete,
                      child: Padding(
                        padding: EdgeInsets.all(5.w),
                        child: Icon(
                          Icons.favorite, // Filled Red Heart logic
                          color: AppTheme.redColor,
                          size: 28.sp, // "little bit bigger to look good"
                        ),
                      ),
                    ),
                  ],
                ),

                if (categoryName != null && categoryName!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 5.h),
                    child: Text(
                      "[$categoryName]",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
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
      fit: BoxFit.contain,
      cacheManager: ImageCacheManager(),
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Widget _buildSoldAsBar() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        final bool showSoldAsProfile =
            dashboard.profileResponse?.results?[0]?.showSoldAs == "Yes";
        if (!showSoldAsProfile) {
          return const SizedBox.shrink();
        }

        if (item.soldAs != null && item.soldAs!.isNotEmpty) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 5.h),
            padding: EdgeInsets.symmetric(vertical: 5.h),
            decoration: BoxDecoration(
              color: AppTheme.tealColor,
            ),
            alignment: Alignment.center,
            child: Text(
              item.soldAs == "Each"
                  ? "Each"
                  : "${item.soldAs} (${item.qtyPerOuter} Units)",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStockStatus() {
    if (item.stockUnlimited == "Yes") return const SizedBox.shrink();

    final bool isOutOfStock = item.qtyStatus == "Out Of Stock";
    if (isOutOfStock) return const SizedBox.shrink();

    String? stockText;
    if (item.qtyStatus == "Low In Stock") {
      stockText = "Low In Stock";
    } else if (item.availableStockQty != null) {
      stockText = "In Stock : ${item.availableStockQty}";
    }

    if (stockText == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 5.h),
      child: Text(
        stockText,
        style: TextStyle(
            color: AppTheme.redColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMOQ() {
    if (item.minimumOrderQty != null &&
        item.minimumOrderQty != "0" &&
        item.minimumOrderQty != "1") {
      return Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Text(
          "MOQ : ${item.minimumOrderQty}",
          style: TextStyle(
              color: AppTheme.redColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

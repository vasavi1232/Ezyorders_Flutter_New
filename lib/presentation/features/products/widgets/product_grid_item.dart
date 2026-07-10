import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/network/image_cache_manager.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/home_models.dart';
import '../../../providers/dashboard_provider.dart';
import 'package:provider/provider.dart';
import '../product_details_screen.dart';
import '../../dashboard/widgets/not_available_dialog.dart';

class ProductGridItem extends StatefulWidget {
  final ProductItem item;
  final VoidCallback? onTap;
  final Function(int qty)? onAddToCart;
  final VoidCallback? onFavorite;
  final bool showSoldAs;

  const ProductGridItem({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToCart,
    this.onFavorite,
    this.showSoldAs = true,
  });

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<ProductGridItem> {
  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    final bool isOutOfStock = widget.item.qtyStatus == "Out Of Stock";
    final bool canAddToCart = widget.item.supplierAvailable == "1" &&
        widget.item.productAvailable == "1" &&
        widget.item.allowToOrder != "No" &&
        !isOutOfStock;
    final bool hasPromotion = widget.item.hasPromotion == "Yes" &&
        widget.item.promotionPrice != null &&
        double.tryParse(widget.item.promotionPrice ?? "0")! > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Card(
        elevation: 1, // Reduced elevation
        color: Colors.white,
        margin: EdgeInsets.all(0), // Removed margin to be tight
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: InkWell(
          onTap: widget.onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailsScreen(productId: widget.item.productId!),
                  ),
                );
              },
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Sold As
              Consumer<DashboardProvider>(
                builder: (context, dashboard, child) {
                  final bool showSoldAsProfile =
                      dashboard.profileResponse?.results?[0]?.showSoldAs ==
                          "Yes";
                  if (!widget.showSoldAs || !showSoldAsProfile) {
                    return const SizedBox.shrink();
                  }

                  if (widget.item.soldAs != null &&
                      widget.item.soldAs!.isNotEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: isLandscape ? 12.h : 5.h), // Increased height in landscape
                      decoration: BoxDecoration(
                        color: AppTheme.tealColor,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.item.soldAs == "Each"
                            ? "Each"
                            : "${widget.item.soldAs} (${widget.item.qtyPerOuter} Units)",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              SizedBox(height: 2.h),

              // Image & Tag
              Consumer<DashboardProvider>(
                builder: (context, dashboard, child) {
                  final dimensions = dashboard.profileResponse?.results?.firstOrNull?.productImageDimensions ?? "600x600";
                  double imageHeight = isLandscape ? 200.h : 90.h;
                  if (dimensions.contains("600x400")) {
                    imageHeight = isLandscape ? 160.h : 75.h;
                  }
                  
                  return Stack(
                    children: [
                      Container(
                        height: imageHeight,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: CachedNetworkImage(
                          imageUrl: _getImageUrl(widget.item.image),
                          fit: BoxFit.contain,
                          cacheManager: ImageCacheManager(),
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[100]),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                      if (widget.item.label != null &&
                          widget.item.label!.isNotEmpty)
                        Positioned(
                          top: 5.h,
                          left: 5.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: AppTheme.redColor,
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                            child: Text(
                              widget.item.label!,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vendor
                    SizedBox(height: 2.h),
                    Text(
                      CommonMethods.htmltag(widget.item.brandName ?? ""),
                      style: TextStyle(
                          color: AppTheme.darkerGrayColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800),
                      maxLines: 1, // Reduced to 1 to prevent overflow
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Title
                    SizedBox(height: 1.h),
                    Text(
                      CommonMethods.htmltag(widget.item.title ?? ""),
                      style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // MOQ
                    if (widget.item.minimumOrderQty != null &&
                        widget.item.minimumOrderQty != "0" &&
                        widget.item.minimumOrderQty != "1")
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          "MOQ : ${widget.item.minimumOrderQty}",
                          style: TextStyle(
                              color: AppTheme.redColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                    // Price Section
                    SizedBox(height: 1.h),
                    if (!hasPromotion)
                      Text(
                        _formatPrice(widget.item.price),
                        style: TextStyle(
                            color: AppTheme.darkerGrayColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatPrice(
                                    widget.item.price), // Original Price (Was)
                                style: TextStyle(
                                    color: AppTheme.darkerGrayColor,
                                    fontSize: 12.sp,
                                    decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w800
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                _formatPrice(widget
                                    .item.promotionPrice), // Promo Price (Now)
                                style: TextStyle(
                                    color: AppTheme.redColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 1.h),
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: AppTheme.redColor,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                            child: Text(
                              "-${CommonMethods.calculateDiscount(widget.item.price, widget.item.promotionPrice)}%",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                    // Stock Status
                    if (widget.item.stockUnlimited != "Yes")
                      Padding(
                        padding: EdgeInsets.only(top: 1.h),
                        child: Builder(builder: (context) {
                          if (isOutOfStock) return const SizedBox.shrink();
                          
                          String stockText = "";
                          if (widget.item.qtyStatus == "Low In Stock") {
                            stockText = "Low In Stock";
                          } else if (widget.item.availableStockQty != null) {
                            stockText = "In Stock : ${widget.item.availableStockQty}";
                          }
                          
                          if (stockText.isEmpty) return const SizedBox.shrink();
                          
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
                  ],
                ),
              ),

              const Spacer(),

              // Actions
              Padding(
                padding: EdgeInsets.all(5.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: isOutOfStock
                                ? null
                                : (canAddToCart && widget.onAddToCart != null
                                    ? () => widget.onAddToCart!(1)
                                    : () {
                                        final supplierName = widget.item.supplierAvailable == "0"
                                            ? (widget.item.brandName ?? widget.item.title ?? "")
                                            : (widget.item.name ?? widget.item.title ?? "");
                                        
                                        showDialog(
                                          context: context,
                                          builder: (context) => NotAvailableDialog(
                                            supplierName: supplierName,
                                            description: widget.item.notAvailableDaysMessage ?? "",
                                          ),
                                        );
                                      }),
                            child: Container(
                              height: isLandscape ? 45.h : 35.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: canAddToCart
                                    ? AppTheme.primaryButtonColor
                                    : AppTheme.redColor,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.productButtonRadius.r),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20.w), // Increased internal padding for responsiveness
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    isOutOfStock
                                        ? "Out Of Stock"
                                        : (widget.item.addedToCart == "Yes"
                                            ? "Update Cart [${widget.item.addedQty ?? '1'}]"
                                            : "Add To Cart"),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Consumer<DashboardProvider>(
                          builder: (context, dashboard, _) {
                            final allowWishlist = dashboard.profileResponse
                                    ?.results?.firstOrNull
                                    ?.allowCustomersToAddWishlist ==
                                "Yes";
                            if (!allowWishlist) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 20.w),
                                InkWell(
                                  onTap: widget.onFavorite,
                                  child: Image.asset(
                                    widget.item.isFavourite == "Yes"
                                        ? "assets/images/favadded.png"
                                        : "assets/images/fav_new.png",
                                    width: 30.h,
                                    height: 30.h,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5.h),
            ],
          ),
        ),
      ),
    ),
  );
}

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    return "${UrlApiKey.mainUrl}$path";
  }

  String _formatPrice(String? price) {
    return CommonMethods.setPriceFormatString(price);
  }
}

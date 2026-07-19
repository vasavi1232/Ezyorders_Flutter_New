import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/network/image_cache_manager.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/home_models.dart';
import '../../products/product_details_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import 'not_available_dialog.dart';

class FlashDealItemWidget extends StatefulWidget {
  final ProductItem item;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onFavorite;

  const FlashDealItemWidget({
    super.key,
    required this.item,
    required this.width,
    this.onTap,
    this.onAddToCart,
    this.onFavorite,
  });

  @override
  State<FlashDealItemWidget> createState() => _FlashDealItemWidgetState();
}

class _FlashDealItemWidgetState extends State<FlashDealItemWidget> {
  Timer? _timer;
  String days = "00";
  String hours = "00";
  String minutes = "00";
  String seconds = "00";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.item.toDate != null) {
        _calculateTimeRemaining(widget.item.toDate!);
      }
    });
  }

  void _calculateTimeRemaining(String toDateStr) {
    try {
      DateTime toDate = DateTime.parse(toDateStr); // Ensure format matches API
      DateTime now = DateTime.now();
      Duration diff = toDate.difference(now);

      if (diff.isNegative) {
        if (mounted) {
          setState(() {
            days = "00";
            hours = "00";
            minutes = "00";
            seconds = "00";
          });
        }
        _timer?.cancel();
        return;
      }

      if (mounted) {
        setState(() {
          days = diff.inDays.toString().padLeft(2, '0');
          hours = (diff.inHours % 24).toString().padLeft(2, '0');
          minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
          seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
        });
      }
    } catch (e) {
      // Handle parse error
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logic similar to ProductItemWidget but with Split layout
    final item = widget.item;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = AppTheme.isTablet(context);
    final bool isTabletLandscape = isLandscape && isTablet;

    final bool isOutOfStock = item.qtyStatus == "Out Of Stock";
    final bool canAddToCart = item.supplierAvailable == "1" &&
        item.productAvailable == "1" &&
        !isOutOfStock;

    final bool hasPromotion = item.hasPromotion == "Yes" &&
        item.promotionPrice != null &&
        double.tryParse(item.promotionPrice ?? "0")! > 0;

    return Container(
      width: widget.width,
      margin: EdgeInsets.only(bottom: 5.h),
      padding: EdgeInsets.only(bottom: 5.h),
      child: Card(
        elevation: 1,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              0.r), // Standardize radius like ProductItemWidget
        ),
        child: InkWell(
          onTap: widget.onTap ??
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
            child: Row(
              children: [
                // Left Side (Image & Info) - Weight 0.52
                Expanded(
                  flex: 52,
                  child: Column(
                    children: [
                      SizedBox(
                        height: isTabletLandscape ? 150.h : 110.h,
                        child: Stack(
                          children: [
                            Center(child: _buildImage(item.image)),
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
                                    (item.label != null &&
                                            item.label!.isNotEmpty)
                                        ? item.label!
                                        : "Flash Deals",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold)),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 5.h),

                      // Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                CommonMethods.decodeHtmlEntities(
                                    item.brandName),
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11.sp,
                                  fontWeight: FontWeight.bold
                                )),
                          Text(CommonMethods.decodeHtmlEntities(item.title),
                              style: TextStyle(
                                  color: AppTheme.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp),
                              maxLines: 2),

                          // Price
                          SizedBox(height: 5.h),
                          if (hasPromotion) ...[
                            Text(_formatPrice(item.price),
                                style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Text(_formatPrice(item.promotionPrice),
                                    style: TextStyle(
                                        color: AppTheme.redColor,
                                        fontSize: 11.sp,
                                      fontWeight: FontWeight.bold
                                    )),
                                SizedBox(width: 5.w),
                                Container(
                                    color: AppTheme.redColor,
                                    padding: EdgeInsets.all(2.w),
                                    child: Text(
                                        "-${CommonMethods.calculateDiscount(item.price, item.promotionPrice)}%",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8.sp))),
                              ],
                            )
                          ] else
                            Text(_formatPrice(item.price),
                                style: TextStyle(
                                    color: AppTheme.darkerGrayColor,
                                    fontSize: 11.sp)),

                          // Add To Cart & Fav Row
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: isOutOfStock
                                      ? null
                                      : (canAddToCart
                                          ? widget.onAddToCart
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
                                    height: isTabletLandscape ? 60.h : (isLandscape ? 45.h : 35.h),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: canAddToCart
                                          ? AppTheme.primaryButtonColor
                                          : AppTheme.redColor,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.productButtonRadius.r),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        isOutOfStock
                                            ? "Out Of Stock"
                                            : (item.addedToCart == "Yes"
                                                ? "Update Cart [${item.addedQty ?? '1'}]"
                                                : "Add To Cart"),
                                        style: TextStyle(
                                            fontSize: isTabletLandscape ? 14.sp : 11.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Consumer<DashboardProvider>(
                                builder: (context, dashboard, child) {
                                  final bool showWishlist = dashboard
                                          .profileResponse
                                          ?.results?[0]
                                          ?.allowCustomersToAddWishlist ==
                                      "Yes";
                                  if (!showWishlist) {
                                    return const SizedBox.shrink();
                                  }

                                  return InkWell(
                                    onTap: widget.onFavorite,
                                    child: Image.asset(
                                      item.isFavourite == "Yes"
                                          ? "assets/images/favadded.png"
                                          : "assets/images/fav_new.png",
                                      width: isTabletLandscape ? 60.h : 30.h,
                                      height: isTabletLandscape ? 60.h : 30.h,
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),

                // Right Side (Timer & Stock) - Weight 0.48
                SizedBox(width: 5.w),
                Expanded(
                  flex: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sold As (Orange)
                      Consumer<DashboardProvider>(
                        builder: (context, dashboard, child) {
                          final bool showSoldAsProfile = dashboard
                                  .profileResponse?.results?[0]?.showSoldAs ==
                              "Yes";
                          if (!showSoldAsProfile) {
                            return const SizedBox.shrink();
                          }

                          if (item.soldAs != null && item.soldAs!.isNotEmpty) {
                            return Container(
                              width: double.infinity,
                              color: AppTheme.tealColor,
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              child: Text(
                                (item.soldAs == "Each")
                                    ? "Each"
                                    : "${item.soldAs} (${item.qtyPerOuter ?? "0"} Units)",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      SizedBox(height: 15.h),

                      // Availability
                      Text("Availability :",
                          style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.7), fontSize: 12.sp)),
                          Text("${item.availableStockQty} In Stock",
                          style: TextStyle(
                              color: AppTheme.tealColor,
                              fontSize: 12.sp,
                              fontWeight:
                                  FontWeight.bold)), // Dynamic stock text

                      SizedBox(height: 15.h),
                      Text("Hurry Up!\nOffers ends in :",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textColor.withValues(alpha: 0.7),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold)),

                      // Timer
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeBox("$days :", "DAYS"),
                          SizedBox(width: 8.w),
                          _buildTimeBox("$hours :", "HOURS"),
                          SizedBox(width: 8.w),
                          _buildTimeBox("$minutes :", "MINS"),
                          SizedBox(width: 8.w),
                          _buildTimeBox(seconds, "SEC"),
                        ],
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                )
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
      fit: BoxFit.contain,
      cacheManager: ImageCacheManager(),
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
                color: AppTheme.textColor)),
        Text(label,
            style: TextStyle(fontSize: 10.sp, color: AppTheme.textColor.withValues(alpha: 0.6))),
      ],
    );
  }
}

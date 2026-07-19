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
import '../product_details_screen.dart';
import '../../dashboard/widgets/not_available_dialog.dart';

class ProductListItem extends StatefulWidget {
  final ProductItem item;
  final VoidCallback? onTap;
  final Function(int qty)? onAddToCart;
  final VoidCallback? onFavorite;
  final bool showSoldAs;

  const ProductListItem({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToCart,
    this.onFavorite,
    this.showSoldAs = true,
  });

  @override
  State<ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<ProductListItem> {
  @override
  Widget build(BuildContext context) {
    // Logic matching ProductslistAdapter.kt
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    // Out of Stock Logic
    final bool isOutOfStock = widget.item.qtyStatus == "Out Of Stock";

    // Supplier/Product Available Logic
    final bool canAddToCart = widget.item.supplierAvailable == "1" &&
        widget.item.productAvailable == "1" &&
        widget.item.allowToOrder != "No" &&
        !isOutOfStock;

    final bool hasPromotion = widget.item.hasPromotion == "Yes" &&
        widget.item.promotionPrice != null &&
        double.tryParse(widget.item.promotionPrice ?? "0")! > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      child: Card(
        elevation: 2,
        color: Colors.white,
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
          child: isTablet 
              ? _buildTabletLayout(isOutOfStock, canAddToCart, hasPromotion)
              : _buildMobileLayout(isOutOfStock, canAddToCart, hasPromotion),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isOutOfStock, bool canAddToCart, bool hasPromotion) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(5.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              _buildImageSection(140.w, 100.h),
              SizedBox(width: 5.w),
              // Details Section
              Expanded(
                child: _buildDetailsSection(hasPromotion),
              ),
            ],
          ),
        ),
        // Actions Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          child: Row(
            children: [
              _buildAddToCartButton(isOutOfStock, canAddToCart),
              const Spacer(),
              _buildWishlistButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(bool isOutOfStock, bool canAddToCart, bool hasPromotion) {
    return Padding(
      padding: EdgeInsets.all(10.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Larger Image Section on Tablet
          _buildImageSection(180.w, 130.h),
          SizedBox(width: 15.w),
          // Details & Actions Section Unified
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSoldAsBar(),
                    _buildBrandAndTitle(),
                    _buildMOQ(),
                    _buildStockStatus(),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPriceSection(hasPromotion),
                    Row(
                      children: [
                        _buildAddToCartButton(isOutOfStock, canAddToCart),
                        SizedBox(width: 15.w),
                        _buildWishlistButton(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(double width, double height) {
    return Stack(
      children: [
        Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: CachedNetworkImage(
            imageUrl: _getImageUrl(widget.item.image),
            fit: BoxFit.contain,
            cacheManager: ImageCacheManager(),
            placeholder: (context, url) => Container(color: Colors.grey[100]),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
          ),
        ),
        if (widget.item.label != null && widget.item.label!.isNotEmpty)
          Positioned(
            top: 5.h,
            left: 5.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.redColor,
                borderRadius: BorderRadius.circular(3.r),
              ),
              child: Text(
                widget.item.label!,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsSection(bool hasPromotion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSoldAsBar(),
        _buildBrandAndTitle(),
        _buildMOQ(),
        _buildStockStatus(),
        SizedBox(height: 5.h),
        _buildPriceSection(hasPromotion),
      ],
    );
  }

  Widget _buildStockStatus() {
    if (widget.item.stockUnlimited == "Yes") return const SizedBox.shrink();

    final bool isOutOfStock = widget.item.qtyStatus == "Out Of Stock";
    if (isOutOfStock) return const SizedBox.shrink();

    String? stockText;
    if (widget.item.qtyStatus == "Low In Stock") {
      stockText = "Low In Stock";
    } else if (widget.item.availableStockQty != null) {
      stockText = "In Stock : ${widget.item.availableStockQty}";
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

  Widget _buildSoldAsBar() {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        final bool showSoldAsProfile =
            dashboard.profileResponse?.results?[0]?.showSoldAs == "Yes";
        if (!widget.showSoldAs || !showSoldAsProfile) {
          return const SizedBox.shrink();
        }

        if (widget.item.soldAs != null && widget.item.soldAs!.isNotEmpty) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 5.h),
            padding: EdgeInsets.symmetric(vertical: isLandscape ? 12.h : 5.h),
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
    );
  }

  Widget _buildBrandAndTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CommonMethods.htmltag(widget.item.brandName ?? ""),
          style: TextStyle(
              color: AppTheme.darkerGrayColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700),
        ),
        Text(
          CommonMethods.htmltag(widget.item.title ?? ""),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor),
        ),
      ],
    );
  }

  Widget _buildMOQ() {
    if (widget.item.minimumOrderQty != null &&
        widget.item.minimumOrderQty != "0" &&
        widget.item.minimumOrderQty != "1") {
      return Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Text(
          "MOQ : ${widget.item.minimumOrderQty}",
          style: TextStyle(
              color: AppTheme.redColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPriceSection(bool hasPromotion) {
    if (!hasPromotion) {
      return Text(
        _formatPrice(widget.item.price),
        style: TextStyle(
            color: AppTheme.darkerGrayColor,
            fontSize: 13.sp,
            fontWeight: FontWeight.w800),
      );
    } else {
      return Row(
        children: [
          Text(
            _formatPrice(widget.item.price),
            style: TextStyle(
                color: AppTheme.darkerGrayColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.lineThrough),
          ),
          SizedBox(width: 5.w),
          Text(
            _formatPrice(widget.item.promotionPrice),
            style: TextStyle(
                color: AppTheme.redColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 5.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppTheme.redColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: Text(
              "-${CommonMethods.calculateDiscount(widget.item.price, widget.item.promotionPrice)}%",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildAddToCartButton(bool isOutOfStock, bool canAddToCart) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    final bool isTabletLandscape = isLandscape && isTablet;
    
    final double buttonHeight = isTabletLandscape ? 60.h : (isLandscape ? 45.h : 35.h);

    return InkWell(
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
        height: buttonHeight,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: canAddToCart ? AppTheme.primaryButtonColor : AppTheme.redColor,
          borderRadius: BorderRadius.circular(AppTheme.productButtonRadius.r),
        ),
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
                fontSize: isTabletLandscape ? 14.sp : 12.sp,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    final bool isTabletLandscape = isLandscape && isTablet;
    
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final allowWishlist = dashboard.profileResponse?.results?.firstOrNull
                ?.allowCustomersToAddWishlist ==
            "Yes";
        if (!allowWishlist) return const SizedBox.shrink();
        return InkWell(
          onTap: widget.onFavorite,
          child: Image.asset(
            widget.item.isFavourite == "Yes"
                ? "assets/images/favadded.png"
                : "assets/images/fav_new.png",
            width: isTabletLandscape ? 60.h : 30.h,
            height: isTabletLandscape ? 60.h : 30.h,
          ),
        );
      },
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

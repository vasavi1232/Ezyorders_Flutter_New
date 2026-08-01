import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/cart_models.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/custom_loader_widget.dart';

class CartUpdateBottomSheet extends StatefulWidget {
  final CartProduct item;
  final Function(int) onUpdate;
  final VoidCallback onDelete;
  final int minQty;
  final int? maxQty; // Made optional
  final int initialQty;

  const CartUpdateBottomSheet({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
    required this.minQty,
    this.maxQty,
    required this.initialQty,
  });

  @override
  State<CartUpdateBottomSheet> createState() => _CartUpdateBottomSheetState();
}

class _CartUpdateBottomSheetState extends State<CartUpdateBottomSheet> {
  late int _quantity;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQty;
    int initialItem = _quantity - widget.minQty;
    if (initialItem < 0) initialItem = 0;
    _scrollController = FixedExtentScrollController(initialItem: initialItem);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletLandscape =
        MediaQuery.of(context).size.shortestSide >= 600 &&
            MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.r),
          topRight: Radius.circular(15.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),

          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 15.w,
                  vertical: isTabletLandscape ? 10.h : 15.h,
                ).copyWith(
                    bottom: (isTabletLandscape ? 10.h : 15.w) +
                        MediaQuery.of(context).padding.bottom),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image & Tag
                          _buildProductImage(isTabletLandscape),
                          SizedBox(width: 15.w),
                          // Product Info
                          Expanded(
                            child: _buildProductDetails(context, isTabletLandscape),
                          ),
                        ],
                      ),

                      SizedBox(height: 15.h),

                      // Min Order Qty & Stock Info
                      _buildStockInfo(),

                      SizedBox(height: 15.h),

                      // Quantity Picker
                      _buildQuantityPicker(isTabletLandscape),

                      SizedBox(height: 15.h),

                      // Action Buttons
                      _buildActionButtons(context, isTabletLandscape),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.r),
          topRight: Radius.circular(15.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2.r,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Product Details",
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.primaryColor, size: 22.sp),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(bool isTabletLandscape) {
    String tagText = "";
    final String status = (widget.item.qtyStatus ?? "").toLowerCase().trim();
    if (status == "best seller" ||
        status == "promotion" ||
        status == "new arrival") {
      tagText = widget.item.qtyStatus!.trim();
    }

    double imageSize = isTabletLandscape ? 180.h : 120.w;

    return Stack(
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: CachedNetworkImage(
            imageUrl: widget.item.image?.startsWith("http") == true
                ? widget.item.image!
                : "${UrlApiKey.mainUrl}${widget.item.image}",
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                Center(child: CustomLoaderWidget(size: 30.w)),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        if (tagText.isNotEmpty)
          Positioned(
            top: 5.h,
            left: 4.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.redColor,
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Text(
                tagText,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductDetails(BuildContext context, bool isTabletLandscape) {
    final dashboardProvider = context.read<DashboardProvider>();
    final showSoldAs =
        dashboardProvider.profileResponse?.results?[0]?.showSoldAs == "Yes";

    final double normalPrice = double.tryParse(widget.item.normalPrice ?? "0") ?? 0;
    final double salePrice = double.tryParse(widget.item.salePrice ?? "0") ?? 0;
    final bool hasPromotion = salePrice > 0 && salePrice < normalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSoldAs &&
            widget.item.orderedAs != null &&
            widget.item.orderedAs!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            margin: EdgeInsets.only(bottom: 5.h),
            decoration: BoxDecoration(
              color: AppTheme.tealColor,
              borderRadius: BorderRadius.circular(0.r),
            ),
            child: Center(
              child: Text(
                widget.item.orderedAs == "Each"
                    ? "Each"
                    : "${widget.item.orderedAs} (${widget.item.qtyPerOuter} Units)",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Text(
          CommonMethods.decodeHtmlEntities(
              widget.item.title?.toUpperCase() ?? ""),
          style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 5.h),
        if (hasPromotion) ...[
          Text(
            CommonMethods.setPriceFormat(normalPrice),
            style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
                fontSize: 13.sp),
          ),
          Row(
            children: [
              Text(
                CommonMethods.setPriceFormat(salePrice),
                style: TextStyle(
                    color: AppTheme.redColor, // Red for promo
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 5.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.redColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: Text(
                  "-${CommonMethods.calculateDiscount(normalPrice.toString(), salePrice.toString())}%",
                  style: TextStyle(color: AppTheme.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                ),
              )
            ],
          )
        ] else
          Text(
            CommonMethods.setPriceFormat(normalPrice),
            style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildStockInfo() {
    final String sunl = (widget.item.stockUnlimited ?? "").toLowerCase().trim();
    final String qstat = (widget.item.qtyStatus ?? "").toLowerCase().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.item.minimumOrderQty != null &&
            widget.item.minimumOrderQty != "1")
          Text(
            "Minimum Order Quantity: ${widget.item.minimumOrderQty}",
            style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold),
          ),
        if (sunl != "yes")
          Builder(builder: (context) {
            String stockText = "Out of Stock";
            if (qstat == "low in stock") {
              stockText = "Low In Stock";
            } else if (widget.item.availableStockQty != null && qstat != "out of stock") {
              stockText = "In Stock : ${widget.item.availableStockQty}";
            }
            
            return Text(
              stockText,
              style: TextStyle(
                  color: AppTheme.redColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold),
            );
          }),
      ],
    );
  }

  Widget _buildQuantityPicker(bool isTabletLandscape) {
    double pickerHeight = isTabletLandscape ? 80.h : 50.h;
    return Container(
      width: double.infinity,
      height: pickerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: SizedBox(
          height: pickerHeight,
          width: isTabletLandscape ? 300.w : 150.w,
          child: RotatedBox(
            quarterTurns: -1,
            child: ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: pickerHeight,
              physics: const FixedExtentScrollPhysics(),
              perspective: 0.002,
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                setState(() {
                  _quantity = widget.minQty + index;
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: (widget.maxQty ?? widget.item.calculateMaxQty()) - widget.minQty + 1,
                builder: (context, index) {
                  int val = widget.minQty + index;
                  bool isSelected = val == _quantity;

                  return RotatedBox(
                    quarterTurns: 1,
                    child: Center(
                      child: Text(
                        "$val",
                        style: TextStyle(
                            fontSize: isSelected ? 24.sp : 18.sp,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[400],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isTabletLandscape) {
    double buttonHeight = isTabletLandscape ? 60.h : 40.h;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ElevatedButton(
            onPressed: () {
              widget.onUpdate(_quantity);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealColor,
              minimumSize: Size(double.infinity, buttonHeight),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r)),
            ),
            child: Text(
              "Update Cart [$_quantity]",
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: () {
            widget.onDelete();
            Navigator.pop(context);
          },
          child: Container(
            width: buttonHeight,
            height: buttonHeight,
            decoration: BoxDecoration(
              color: AppTheme.redColor,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
          ),
        ),
      ],
    );
  }
}

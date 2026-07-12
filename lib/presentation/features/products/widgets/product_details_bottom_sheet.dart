import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/home_models.dart';

import '../../../providers/product_list_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/additional_suppliers_dialog.dart';
import '../../../widgets/custom_loader_widget.dart';
import '../../../widgets/specials_tooltip.dart';
import './cart_success_dialog.dart';

class ProductDetailsBottomSheet extends StatefulWidget {
  final ProductItem product;

  const ProductDetailsBottomSheet({super.key, required this.product});

  @override
  State<ProductDetailsBottomSheet> createState() =>
      _ProductDetailsBottomSheetState();
}

class _ProductDetailsBottomSheetState extends State<ProductDetailsBottomSheet> {
  String _selectedSoldAs = "Each";
  int _selectedQty = 1;
  late FixedExtentScrollController _qtyScrollController;
  final GlobalKey _percentageStripKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedSoldAs = widget.product.orderedAs ?? "Each";
    _selectedQty = int.tryParse(widget.product.addedQty ?? "1") ?? 1;
    if (_selectedQty < 1) _selectedQty = 1;

    _qtyScrollController =
        FixedExtentScrollController(initialItem: _selectedQty - 1);
  }

  @override
  void dispose() {
    _qtyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.read<DashboardProvider>();
    final showSoldAs =
        dashboardProvider.profileResponse?.results?[0]?.showSoldAs == "Yes";

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
                padding: EdgeInsets.all(15.w).copyWith(
                    bottom: 15.w + MediaQuery.of(context).padding.bottom),
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
                          _buildProductImage(),
                          SizedBox(width: 15.w),
                          // Product Info
                          Expanded(
                            child: _buildProductDetails(showSoldAs, dashboardProvider),
                          ),
                        ],
                      ),

                      SizedBox(height: 15.h),

                      // Min Order Qty & Stock Info
                      _buildStockInfo(),

                      SizedBox(height: 15.h),

                      // Quantity Picker
                      _buildQuantityPicker(),

                      SizedBox(height: 15.h),

                      // Action Buttons
                      _buildActionButtons(context),
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

  Widget _buildProductImage() {
    // Simplified tag logic matching Android pdTagTxt
    String tagText = "";

    // Priority: Label (Best Seller/Hot Selling) -> Promotion -> New Arrival
    if (widget.product.label != null && widget.product.label!.isNotEmpty) {
      tagText = widget.product.label!;
    } else if (widget.product.hasPromotion == "Yes") {
      tagText = "Promotion";
    } else if (widget.product.qtyStatus == "New Arrival") {
      tagText = "New Arrival";
    }

    return Stack(
      children: [
        Container(
          width: 150.w,
          height: 150.w,
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: CachedNetworkImage(
            imageUrl: widget.product.image?.startsWith("http") == true
                ? widget.product.image!
                : "${UrlApiKey.mainUrl}${widget.product.image}",
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                Center(child: CustomLoaderWidget(size: 30.w)),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        if (tagText.isNotEmpty)
          Positioned(
            top: 5.h,
            left: 5.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.redColor, // Red stripe
                borderRadius: BorderRadius.circular(3.r),
              ),
              child: Text(
                tagText,
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

  Widget _buildProductDetails(bool showSoldAs, DashboardProvider provider) {
    // Match Dashboard Logic: Always show Unit Price
  double basePrice = double.tryParse(widget.product.price ?? "0.0") ?? 0.0;
  double basePromoPrice =
      double.tryParse(widget.product.promotionPrice ?? "0.0") ?? 0.0;

  double currentPrice;
  double currentPromoPrice;

  if (_selectedSoldAs == "Carton" && widget.product.soldAs == "Each") {
    int units = int.tryParse(widget.product.qtyPerOuter ?? "1") ?? 1;
    currentPrice = basePrice * units;
    currentPromoPrice = basePromoPrice * units;
  } else {
    currentPrice = basePrice;
    currentPromoPrice = basePromoPrice;
  }

    bool hasPromo =
        widget.product.hasPromotion == "Yes" && currentPromoPrice > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSoldAs)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: 10.w, vertical: 4.h), // Match Dashboard padding
            margin: EdgeInsets.only(bottom: 5.h),
            decoration: BoxDecoration(
              color: AppTheme.tealColor,
              borderRadius: BorderRadius.circular(0
                  .r), // Match Dashboard (Square/small radius) - Dashboard uses 0.r or small
            ),
            child: Center(
              child: Text(
                widget.product.soldAs == "Each"
                    ? "Each" // Dashboard shows "Each" or "Carton (X Units)"
                    : "${widget.product.soldAs} (${widget.product.qtyPerOuter} Units)",
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

        Text(
          CommonMethods.decodeHtmlEntities(widget.product.brandName ?? ""),
          style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12.sp,
              fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 2.h),
        Text(
          CommonMethods.decodeHtmlEntities(
              widget.product.title ?? widget.product.name ?? ""),
          style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: 5.h),

        // Pricing
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (hasPromo) {
              final String dId = (widget.product.specialId ?? widget.product.discountId ?? "").trim();
              final String dName = (widget.product.specialName ?? widget.product.discountName ?? "").trim();
              
              if (dId.isNotEmpty || dName.isNotEmpty) {
                final RenderBox? box = _percentageStripKey.currentContext?.findRenderObject() as RenderBox?;
                if (box != null) {
                  final position = box.localToGlobal(Offset.zero);
                  final rect = position & box.size;
                  SpecialsTooltip.show(
                    context,
                    discountId: dId,
                    discountName: dName,
                    targetRect: rect,
                  );
                } else {
                  SpecialsTooltip.show(
                    context,
                    discountId: dId,
                    discountName: dName,
                    tapPosition: details.globalPosition,
                  );
                }
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPromo) ...[
                Text(
                  CommonMethods.setPriceFormat(currentPrice),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13.sp,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      CommonMethods.setPriceFormat(currentPromoPrice),
                      style: TextStyle(
                          color: AppTheme.redColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 5.w),
                    Container(
                      key: _percentageStripKey,
                      padding:
                          EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.redColor,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                      child: Text(
                        "-${CommonMethods.calculateDiscount(currentPrice.toString(), currentPromoPrice.toString())}%",
                        style: TextStyle(color: Colors.white, fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  CommonMethods.setPriceFormat(currentPrice),
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 5.h),

        // Sold As Spinner - only if show_sold_as is Yes and qtyPerOuter > 1, AND soldAs == Each
      if (showSoldAs &&
          provider.profileResponse?.results?.firstOrNull
                  ?.allowCartonLevelPurchaseOfEach !=
              "No" &&
          widget.product.soldAs == "Each" &&
          (int.tryParse(widget.product.qtyPerOuter ?? "1") ?? 1) > 1)
        Container(
          height: 42.h,
          width: double.infinity,
          margin: EdgeInsets.only(top: 5.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(5.r),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSoldAs,
              isExpanded: true,
              items: ["Each", "Carton"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSoldAs = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    if (widget.product.qtyStatus == "Out Of Stock") return const SizedBox.shrink();

    String? stockText;
    if (widget.product.qtyStatus == "Low In Stock") {
      stockText = "Low In Stock";
    } else if (widget.product.stockUnlimited == "No" && widget.product.availableStockQty != null) {
      stockText = "In Stock: ${widget.product.availableStockQty}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.product.minimumOrderQty != null &&
            widget.product.minimumOrderQty != "1")
          Text(
            "Minimum Order Quantity: ${widget.product.minimumOrderQty}",
            style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold),
          ),
        if (stockText != null)
          Text(
            stockText,
            style: TextStyle(
                color: Colors.red,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildQuantityPicker() {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = AppTheme.isTablet(context);

    return Container(
      width: double.infinity,
      height: (isLandscape && isTablet) ? 85.h : 50.h,
      color: const Color(0xFFEEEEEE), // Grey Background
      child: Center(
        child: SizedBox(
          height: (isLandscape && isTablet) ? 85.h : 50.h,
          width: 150.w, // Approx 3 items * 50 width
          child: RotatedBox(
            quarterTurns: -1,
            child: ListWheelScrollView.useDelegate(
              controller: _qtyScrollController,
              itemExtent: 50.w, // Visual Width of each item
              physics: const FixedExtentScrollPhysics(),
              perspective: 0.002, // Subtle curve
              diameterRatio: 1.5,
              onSelectedItemChanged: (index) {
                int minQty =
                    int.tryParse(widget.product.minimumOrderQty ?? "0") ?? 1;
                if (minQty == 0) minQty = 1;
                int newQty = minQty + index;

                if (newQty != _selectedQty) {
                  setState(() {
                    _selectedQty = newQty;
                  });
                }
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: () {
                  int minQty =
                      int.tryParse(widget.product.minimumOrderQty ?? "0") ?? 1;
                  if (minQty == 0) minQty = 1;

                  int maxQty;
                  if (widget.product.stockUnlimited == "Yes" ||
                      widget.product.qtyStatus == "Low In Stock") {
                    maxQty = 1000;
                  } else {
                    maxQty = int.tryParse(
                            widget.product.availableStockQty ?? "0") ??
                        100;
                  }

                  if (maxQty < minQty) maxQty = minQty;

                  return maxQty - minQty + 1;
                }(),
                builder: (context, index) {
                  int minQty =
                      int.tryParse(widget.product.minimumOrderQty ?? "0") ?? 1;
                  if (minQty == 0) minQty = 1;
                  int val = minQty + index;

                  bool isSelected = val == _selectedQty;

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
                      ));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final provider = context.watch<ProductListProvider>();
    bool isAdded = widget.product.addedToCart == "Yes";
    bool isLoading = provider.isLoading;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = AppTheme.isTablet(context);

    double buttonHeight = (isLandscape && isTablet) ? 75.h : 40.h;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    final dashboardProvider = context.read<DashboardProvider>();
                    final profile = dashboardProvider.profileResponse;
                    final result = profile?.results?.isNotEmpty == true
                        ? profile!.results![0]
                        : null;

                    if (result == null) {
                      _performCartAction(provider, isAdded);
                      return;
                    }

                    int currentSupplierCount = CommonMethods.supplierCount;
                    int maxSupplierCount = int.tryParse(result
                                .maximumNumberOfSuppliersProductsForFreeShipping ??
                            "0") ??
                        0;
                    String currentSuppliers = CommonMethods.suppliers;
                    String productBrandId = widget.product.brandId ?? "";

                    bool isSupplierInList = false;
                    if (currentSuppliers.isNotEmpty) {
                      List<String> supplierList = currentSuppliers.split(",");
                      isSupplierInList = supplierList.contains(productBrandId);
                    }

                    String showShippingSegment =
                        result.showShippingSegment ?? "";

                    // Logic: If limit reached AND new supplier AND shipping segment enabled AND NOT free shipping for unlimited suppliers
                    if (currentSupplierCount >= maxSupplierCount &&
                        !isSupplierInList &&
                        showShippingSegment == "Yes" &&
                        result.freeShippingForUnlimitedSupplierProducts !=
                            "Yes") {
                      showDialog(
                        context: context,
                        builder: (context) => AdditionalSuppliersDialog(
                          message: result
                                  .customerMessageForAdditionalSuppliersCharge ??
                              "Extra charges apply for additional suppliers.",
                          onContinue: () =>
                              _performCartAction(provider, isAdded),
                        ),
                      );
                    } else {
                      _performCartAction(provider, isAdded);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppTheme.primaryButtonColor, // Synchronized orange
              minimumSize: Size(double.infinity, buttonHeight),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.authButtonRadius.r)),
            ),
            child: isLoading
                ? CustomLoaderWidget(size: 20.h)
                : Text(
                    isAdded
                        ? "Update Cart [${widget.product.addedQty}]"
                        : "Add To Cart",
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
          ),
        ),
        if (isAdded) ...[
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: () async {
              await provider.deleteFromCart(widget.product);
              if (context.mounted) {
                context
                    .read<DashboardProvider>()
                    .setCartCount(CommonMethods.cartCount);
                Navigator.pop(context);
              }
            },
            child: Container(
              width: buttonHeight,
              height: buttonHeight,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius:
                    BorderRadius.circular(AppTheme.authButtonRadius.r),
              ),
              child: Icon(Icons.delete, color: Colors.white, size: 26.sp),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _performCartAction(
      ProductListProvider provider, bool isAdded) async {
    bool success = false;
    if (isAdded) {
      success = await provider.updateCart(
          widget.product, _selectedQty.toString(), _selectedSoldAs);
    } else {
      success = await provider.addToCart(
          widget.product, _selectedQty.toString(), _selectedSoldAs);
    }

    if (mounted && success) {
      context.read<DashboardProvider>().setCartCount(CommonMethods.cartCount);
      Navigator.pop(context); // Close bottom sheet

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return CartSuccessDialog(
            productName:
                widget.product.title ?? widget.product.name ?? "Product",
            isUpdate: isAdded,
          );
        },
      );
    }
  }
}

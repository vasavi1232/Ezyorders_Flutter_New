import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/home_models.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/additional_suppliers_dialog.dart';
import '../../../widgets/specials_tooltip.dart';
import 'cart_success_dialog.dart';

class ProductDetailsBottomSheet extends StatefulWidget {
  final ProductItem product;
  final String? badgeLabel;

  const ProductDetailsBottomSheet({
    super.key,
    required this.product,
    this.badgeLabel,
  });

  @override
  State<ProductDetailsBottomSheet> createState() =>
      _ProductDetailsBottomSheetState();
}

class _ProductDetailsBottomSheetState extends State<ProductDetailsBottomSheet> {
  late String _selectedSoldAs;
  late double _currentPrice;
  late double _currentPromoPrice;

  int _quantity = 0;
  List<String> _soldAsOptions = [];

  late FixedExtentScrollController _scrollController;
  final GlobalKey _percentageStripKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize defaults
    // Logic: If orderedAs is set, try to match it.
    // Build options dynamically
    String qtyPerOuter = widget.product.qtyPerOuter ?? "1";
    _soldAsOptions = ["Each"];
    if (widget.product.qtyPerOuter != null && int.parse(qtyPerOuter) > 1) {
      _soldAsOptions.add("Carton");
    }

    if (widget.product.addedToCart == "Yes") {
      _selectedSoldAs = widget.product.orderedAs ?? "Each";
    } else {
      _selectedSoldAs = "Each";
    }

    // Handle case where orderedAs might be just "Carton" but we display "Carton (x Units)"
    // Or map back/forth.
    if (_selectedSoldAs == "Carton") {
      _selectedSoldAs = "Carton";
    }

    _calculatePrices();

    // Initialize Quantity
    int minQty = int.tryParse(widget.product.minimumOrderQty ?? "0") ?? 1;
    if (minQty == 0) minQty = 1;

    if (widget.product.addedToCart == "Yes") {
      _quantity = int.tryParse(widget.product.addedQty ?? "0") ?? 0;
    } else {
      _quantity = minQty;
    }

    // Ensure quantity is valid wrt min
    if (_quantity < minQty) _quantity = minQty;

    int initialItem = _quantity - minQty;
    if (initialItem < 0) initialItem = 0;

    _scrollController = FixedExtentScrollController(initialItem: initialItem);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _calculatePrices() {
    double basePrice = double.tryParse(widget.product.price ?? "0") ?? 0;
    double basePromo =
        double.tryParse(widget.product.promotionPrice ?? "0") ?? 0;

    // Only multiply if it's sold as Each but ordered as Carton (via dropdown)
    if (_selectedSoldAs == "Carton" && widget.product.soldAs == "Each") {
      int units = int.tryParse(widget.product.qtyPerOuter ?? "1") ?? 1;
      _currentPrice = basePrice * units;
      _currentPromoPrice = basePromo * units;
    } else {
      _currentPrice = basePrice;
      _currentPromoPrice = basePromo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final bool showSoldAs =
        provider.profileResponse?.results?.isNotEmpty == true &&
        provider.profileResponse?.results?[0]?.showSoldAs == "Yes";

    final bool hasPromotion = widget.product.hasPromotion == "Yes" &&
        (double.tryParse(widget.product.promotionPrice ?? "0") ?? 0) > 0;
    final bool isAdded = widget.product.addedToCart == "Yes";
    
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = AppTheme.isTablet(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(0.r)), // Match rounded top
      ),
      padding: EdgeInsets.all(15.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Product Details",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close,
                      color: AppTheme.primaryColor, size: 22.sp),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),

          SizedBox(
            height: 10.h,
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + Badge + Sold As Strip
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.image?.startsWith("http") ==
                                  true
                              ? widget.product.image!
                              : "${UrlApiKey.mainUrl}${widget.product.image}",
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                      // Status Badge
                      if (widget.badgeLabel != null &&
                          widget.badgeLabel!.isNotEmpty)
                        Positioned(
                          top: 5.h,
                          left: 4.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.redColor,
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                            child: Text(
                              widget.badgeLabel!,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.product.stockUnlimited != "Yes") ...[
                    SizedBox(height: 5.h),
                    Text(
                      widget.product.qtyStatus == "Low In Stock"
                          ? widget.product.qtyStatus!
                          : "In Stock : ${widget.product.availableStockQty ?? '0'}",
                      style: TextStyle(
                          color: AppTheme.redColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
              SizedBox(width: 10.w),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sold As Strip (Moved here)
                    if (showSoldAs && widget.product.soldAs != null)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 5.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppTheme.tealColor,
                          borderRadius: BorderRadius.circular(0.r),
                        ),
                        child: Center(
                          child: Text(
                            widget.product.soldAs == "Each"
                                ? "Each"
                                : "${widget.product.soldAs} (${widget.product.qtyPerOuter ?? "1"} Units)",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    // Tag
                    /* if (widget.product.divisionId != null) // Tag check generic
                      Text(
                        CommonMethods.decodeHtmlEntities(
                            widget.product.divisionId!),
                        // Using division as category placeholder? Android uses category field which I might not have mapped fully in ProductItem logic but is in response.
                        style: TextStyle(
                            color: AppTheme.tealColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold),
                      ),*/

                    Text(
                      CommonMethods.decodeHtmlEntities(
                          widget.product.brandName),
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      CommonMethods.decodeHtmlEntities(
                          widget.product.title ?? widget.product.name ?? ""),
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp),
                      maxLines: 2,
                    ),

                    SizedBox(height: 5.h),

                    // Prices
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        if (hasPromotion) {
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
                              // Fallback to tap position if key context not found
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
                          if (hasPromotion) ...[
                            Text(
                              CommonMethods.setPriceFormat(_currentPrice),
                              style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 13.sp),
                            ),
                            Row(
                              children: [
                                Text(
                                  CommonMethods.setPriceFormat(
                                      _currentPromoPrice),
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 5.w),
                                Container(
                                  key: _percentageStripKey,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 5.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppTheme.redColor,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                  child: Text(
                                    "-${CommonMethods.calculateDiscount(_currentPrice.toString(), _currentPromoPrice.toString())}%",
                                    style: TextStyle(
                                        color: AppTheme.white, fontSize: 10.sp),
                                  ),
                                )
                              ],
                            )
                          ] else
                            Text(
                              CommonMethods.setPriceFormat(_currentPrice),
                              style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // Dropdown / Sold As logic
                    if (provider.profileResponse?.results?.firstOrNull
                                ?.showSoldAs ==
                            "Yes" &&
                        provider.profileResponse?.results?.firstOrNull
                                ?.allowCartonLevelPurchaseOfEach !=
                            "No" &&
                        widget.product.soldAs == "Each" &&
                        (int.tryParse(widget.product.qtyPerOuter ?? "1") ?? 1) > 1)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5.r),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSoldAs,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.black54),
                            items: _soldAsOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedSoldAs = newValue;
                                  _calculatePrices();
                                });
                              }
                            },
                          ),
                        ),
                      )
                  ],
                ),
              )
            ],
          ),

          SizedBox(height: 15.h),

          // Min Qty / Stock (Keep below row) -> Actually min qty might be hidden based on screenshot, but let's keep it for logic.
          // Screenshot shows Quantity Picker immediately after.

          // Quantity Picker (Horizontal Snapping)
          // "Center auto select on scroll" -> PageView with viewportFraction (0.33)
          // "3 Digit Visible" -> Constrained width (e.g. 180)
          // Quantity Picker (Horizontal Wheel)
          // Rotated ListWheelScrollView for 3-item visible "Wheel" effect
          Container(
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
                    controller: _scrollController,
                    itemExtent: 50.w, // Visual Width of each item
                    physics: const FixedExtentScrollPhysics(),
                    perspective: 0.002, // Subtle curve
                    diameterRatio: 1.5,
                    onSelectedItemChanged: (index) {
                      int minQty =
                          int.tryParse(widget.product.minimumOrderQty ?? "0") ??
                              1;
                      if (minQty == 0) minQty = 1;
                      int newQty = minQty + index;

                      if (newQty != _quantity) {
                        setState(() {
                          _quantity = newQty;
                        });
                      }
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: () {
                        int minQty = int.tryParse(
                                widget.product.minimumOrderQty ?? "0") ??
                            1;
                        if (minQty == 0) minQty = 1;
                        
                        int maxQty;
                        final String sunl = (widget.product.stockUnlimited ?? "").toLowerCase().trim();
                        final String qstat = (widget.product.qtyStatus ?? "").toLowerCase().trim();
                        final String ato = (widget.product.allowToOrder ?? "").toLowerCase().trim();

                        if (sunl == "yes" ||
                            qstat == "low in stock" ||
                            ato == "yes" ||
                            ato == "1") {
                          maxQty = 1000;
                        } else {
                          maxQty = int.tryParse(widget.product.availableStockQty ?? "0") ?? 100;
                        }
                        
                        if (maxQty < minQty) maxQty = minQty;
                        
                        return maxQty - minQty + 1;
                      }(),
                      builder: (context, index) {
                        int minQty = int.tryParse(
                                widget.product.minimumOrderQty ?? "0") ??
                            1;
                        if (minQty == 0) minQty = 1;
                        int val = minQty + index;

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
                            ));
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: (isLandscape && isTablet) ? 75.h : (isLandscape ? 50.h : 45.h),
                  child: ElevatedButton(
                    onPressed: () {
                      // Add/Update Cart Logic
                      // If validation passes
                      _addToCart(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryButtonColor,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      isAdded ? "Update Cart [$_quantity]" : "Add To Cart",
                      style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              if (isAdded) ...[
                SizedBox(width: 10.w),
                InkWell(
                    onTap: () {
                      provider.deleteCart(widget.product.productId!,
                          widget.product.brandId ?? "");
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: (isLandscape && isTablet) ? 75.h : null,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppTheme.redColor,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ))
              ], 
            ], 
          ),
        ], 
      ), 
    ); 
  }

  void _addToCart(BuildContext context) {
    final provider = context.read<DashboardProvider>();
    final profile = provider.profileResponse;
    final result =
        profile?.results?.isNotEmpty == true ? profile!.results![0] : null;

    if (result == null) return;

    int currentSupplierCount = CommonMethods.supplierCount;
    int maxSupplierCount = int.tryParse(
            result.maximumNumberOfSuppliersProductsForFreeShipping ?? "0") ??
        0;
    String currentSuppliers = CommonMethods.suppliers;
    String productBrandId = widget.product.brandId ?? "";

    bool isSupplierInList = false;
    if (currentSuppliers.isNotEmpty) {
      List<String> supplierList = currentSuppliers.split(",");
      isSupplierInList = supplierList.contains(productBrandId);
    }

    String showShippingSegment = result.showShippingSegment ?? "";

    // Logic: If limit reached AND new supplier AND shipping segment enabled AND NOT free shipping for unlimited suppliers
    if (currentSupplierCount >= maxSupplierCount &&
        !isSupplierInList &&
        showShippingSegment == "Yes" &&
        result.freeShippingForUnlimitedSupplierProducts != "Yes") {
      showDialog(
        context: context,
        builder: (context) => AdditionalSuppliersDialog(
          message: result.customerMessageForAdditionalSuppliersCharge ??
              "Extra charges apply for additional suppliers.",
          onContinue: () => _performAddToCart(provider),
        ),
      );
    } else {
      _performAddToCart(provider);
    }
  }

  Future<void> _performAddToCart(DashboardProvider provider) async {
    String cleanSoldAs =
        _selectedSoldAs.startsWith("Carton") ? "Carton" : "Each";

    bool success = false;
    bool isUpdate = widget.product.addedToCart == "Yes";

    // Fix: Ensure we send the correct price (Promo if valid, else Base)
    double priceToSend = _currentPromoPrice;
    if (priceToSend <= 0) {
      priceToSend = _currentPrice;
    }

    // Note: Backend might expect exactly 2 decimals in some cases, but native Android 
    // uses the dynamic decimalDigits for EVERYTHING including API.
    // So we use it here too.
    final String priceString = priceToSend.toStringAsFixed(CommonMethods.decimalDigits);

    if (isUpdate) {
      success = await provider.updateCart(
          widget.product.productId!,
          _quantity.toString(),
          widget.product.brandId ?? "",
          priceString,
          cleanSoldAs);
    } else {
      success = await provider.addToCart(
          widget.product.productId!,
          _quantity.toString(),
          priceString,
          cleanSoldAs,
          widget.product.apiData ?? "",
          widget.product.brandId ?? "");
    }

    if (mounted) {
      // Capture the navigator before popping the bottom sheet
      final navigator = Navigator.of(context);
      navigator.pop(); 

      if (success) {
        // Use the root navigator context to show the dialog safely over the dashboard
        showDialog(
          context: navigator.context,
          barrierDismissible: true,
          builder: (context) => CartSuccessDialog(
            productName: widget.product.title ?? "Product",
            isUpdate: isUpdate,
          ),
        );
      }
    }
  }
}

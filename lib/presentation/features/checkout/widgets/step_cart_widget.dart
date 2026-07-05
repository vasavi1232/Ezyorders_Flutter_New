import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../providers/checkout_provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/gst_message_widget.dart';
import '../../cart/widgets/delivery_location_dialog.dart';
import 'cart_item_refined_widget.dart';
import 'clear_cart_dialog.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/delivery_location_response.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StepCartWidget extends StatefulWidget {
  const StepCartWidget({super.key});

  @override
  State<StepCartWidget> createState() => _StepCartWidgetState();
}

class _StepCartWidgetState extends State<StepCartWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckoutProvider>();
    final cartResult = provider.cartResult;

    // Error State
    if (!provider.isLoading && provider.errorMessage.isNotEmpty && (cartResult == null || (cartResult.brands?.isEmpty ?? true))) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
              SizedBox(height: 10.h),
              Text(
                provider.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.red),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  provider.clearError();
                  provider.refreshCartSummary(provider.customerId, provider.accessToken);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryButtonColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(120.w, 40.h),
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (cartResult == null || (cartResult.brands?.isEmpty ?? true)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 60.sp, color: Colors.grey),
            SizedBox(height: 10.h),
            Text("No Products added to Cart.",
                style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey)),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                context.read<DashboardProvider>().refreshDashboard();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryButtonColor,
                foregroundColor: Colors.white,
                minimumSize: Size(150.w, 40.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r)),
              ),
              child: const Text("Back to Home"),
            )
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    GstMessageWidget(),
                    // Cart Items List Grouped by Brand
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartResult.brands?.length ?? 0,
                      itemBuilder: (context, index) {
                        final brand = cartResult.brands![index];
                        if (brand == null) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Brand Header removed to match Android native parity (duplicate brand name)
                            // Products
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: brand.products?.length ?? 0,
                              itemBuilder: (context, pIndex) {
                                final product = brand.products![pIndex];
                                if (product == null) return const SizedBox.shrink();

                                return CartItemRefinedWidget(
                                  item: product,
                                  showHeader: false,
                                  showBrand: pIndex == 0,
                                  brandName: brand.brandName ?? "",
                                  brandId: brand.brandId ?? "",
                                  onUpdateQty: (newQty) async {
                                    double basePrice = double.tryParse(product.salePrice ?? "0") ?? 0;
                                    if (basePrice <= 0) {
                                      basePrice = double.tryParse(product.normalPrice ?? "0") ?? 0;
                                    }
                                    
                                    await provider.updateCartItem(
                                        product.productId!,
                                        newQty,
                                        brand.brandId!,
                                        basePrice.toStringAsFixed(2),
                                        product.orderedAs ?? "");
                                    
                                    if (context.mounted) {
                                      context.read<DashboardProvider>().setCartCount(CommonMethods.cartCount);
                                    }
                                  },
                                  onDelete: () async {
                                    await provider.deleteCartItem(
                                        product.productId!, brand.brandId!);
                                    if (context.mounted) {
                                      context.read<DashboardProvider>().setCartCount(CommonMethods.cartCount);
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section (Price Details & Actions)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, -3),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Expandable Price Details header
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Cart Total",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: AppTheme.primaryColor),
                          ),
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryButtonColor,
                            ),
                            child: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isExpanded)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Delivery Location Selection
                          if (context.read<DashboardProvider>().profileResponse?.results?.firstOrNull?.showShippingSegment == "Yes" && provider.deliveryLocations.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.shippingSegmentHeading,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                if (provider.shippingSegmentText.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    provider.shippingSegmentText,
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade700),
                                  ),
                                ],
                                SizedBox(height: 10.h),
                                Text(
                                  "Delivery Location",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => DeliveryLocationDialog(
                                        deliveryLocations: provider.deliveryLocations,
                                        selectedDeliveryLocationId: provider.selectedDeliveryLocationId,
                                        onLocationSelected: (locationId, charge) {
                                          provider.updateDeliveryLocation(locationId, charge);
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderColor),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            provider.selectedDeliveryLocationId == null
                                                ? "Select Delivery Location"
                                                : () {
                                                    final bool exists = provider.deliveryLocations.any((loc) => loc.deliveryLocationId == provider.selectedDeliveryLocationId);
                                                    if (!exists) return "Select Delivery Location";
                                                    final selectedLoc = provider.deliveryLocations.firstWhere(
                                                        (loc) => loc.deliveryLocationId == provider.selectedDeliveryLocationId);
                                                    String displayText = selectedLoc.locationName ?? "Select Delivery Location";
                                                    if (selectedLoc.subLocationName != null && selectedLoc.subLocationName!.isNotEmpty) {
                                                      displayText += " - ${selectedLoc.subLocationName}";
                                                    }
                                                    return displayText;
                                                  }(),
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: provider.selectedDeliveryLocationId == null
                                                  ? Colors.grey.shade600
                                                  : AppTheme.primaryColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                if (provider.selectedDeliveryLocationId != null)
                                  Builder(builder: (context) {
                                    final selectedLoc = provider.deliveryLocations.firstWhere(
                                        (loc) => loc.deliveryLocationId == provider.selectedDeliveryLocationId,
                                        orElse: () => DeliveryLocationResult());
                                    String displayText = selectedLoc.locationName ?? "";
                                    if (selectedLoc.subLocationName != null && selectedLoc.subLocationName!.isNotEmpty) {
                                      displayText += " - ${selectedLoc.subLocationName}";
                                    }
                                    return RichText(
                                      text: TextSpan(
                                        text: "Selected Delivery Location : ",
                                        style: TextStyle(fontSize: 13.sp, color: AppTheme.primaryColor),
                                        children: [
                                          TextSpan(
                                            text: displayText,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          _buildSummaryRow(
                              provider.subTotalHeading,
                              CommonMethods.setPriceFormatString(provider.subTotal),
                              isBlueValue: true),

                          Builder(builder: (context) {
                            final profile = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull;
                            final showLevy = profile?.showLevy == "Yes";
                            final includeLevy = profile?.includeLevyInPriceCalculation == "No";
                            final hasLevy = (double.tryParse(provider.levy) ?? 0) > 0;
                             if (showLevy && includeLevy && hasLevy) {
                              return _buildSummaryRow("Levy :", CommonMethods.setPriceFormatString(provider.levy), isBlueValue: true);
                            }
                            return const SizedBox.shrink();
                          }),

                          Builder(builder: (context) {
                            final profile = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull;
                            final showWet = profile?.showWet == "Yes";
                            final includeWet = profile?.includeWetInPriceCalculation == "No";
                            final hasWet = (double.tryParse(provider.wet) ?? 0) > 0;
                             if (showWet && includeWet && hasWet) {
                              return _buildSummaryRow("WET :", CommonMethods.setPriceFormatString(provider.wet), isBlueValue: true);
                            }
                            return const SizedBox.shrink();
                          }),

                          if (context.read<DashboardProvider>().profileResponse?.results?.firstOrNull?.showShippingSegment == "Yes" &&
                              (double.tryParse(provider.shippingCharge) ?? 0) > 0)
                            _buildSummaryRow("Shipping :",
                                CommonMethods.setPriceFormatString(provider.shippingCharge),
                                isBlueValue: true),

                          if (context.read<DashboardProvider>().profileResponse?.results?.firstOrNull?.showShippingSegment != "Yes" &&
                              (double.tryParse(provider.shippingCharge) ?? 0) > 0)
                            _buildSummaryRow("Shipping :",
                                CommonMethods.setPriceFormatString(provider.shippingCharge),
                                isBlueValue: true),

                          Builder(builder: (context) {
                            final profile = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull;
                            final showPriceIncGst = profile?.showPriceIncludingGst ?? "No";
                            final showGstInCart = profile?.showGstInCart ?? "No";
                            final taxTotalVal = double.tryParse(provider.taxTotal) ?? 0;

                            if (taxTotalVal > 0 || (showPriceIncGst == "No" && showGstInCart == "Yes")) {
                              return _buildSummaryRow("GST :", CommonMethods.setPriceFormatString(provider.taxTotal), isBlueValue: true);
                            }
                            return const SizedBox.shrink();
                          }),

                          if ((double.tryParse(provider.supplierCharge) ?? 0) > 0)
                            _buildSummaryRow("Addnl. Supplier Charge :", CommonMethods.setPriceFormatString(provider.supplierCharge), isBlueValue: true),

                          if ((double.tryParse(provider.couponDiscount) ?? 0) > 0)
                            _buildSummaryRow("Coupon (${provider.couponName})", "-${CommonMethods.setPriceFormatString(provider.couponDiscount)}", isDiscount: true),

                          const SizedBox(height: 10),
                          _buildSummaryRow(
                              provider.totalHeading,
                              CommonMethods.setPriceFormatString(provider.totalAmount),
                              isBlueValue: true),
                          SizedBox(height: 5.h),
                        ],
                      ),
                    ),

                  // Action Buttons
                  Padding(
                    padding: EdgeInsets.all(15.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w),
                            child: SizedBox(
                              height: 45.h,
                              child: ElevatedButton(
                                onPressed: () => _showClearCartDialog(context, provider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.redColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text("Clear Cart", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold), maxLines: 1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("${provider.currentStep + 1}/${provider.totalSteps}",
                                  maxLines: 1,
                                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w),
                            child: SizedBox(
                              height: 45.h,
                              child: ElevatedButton(
                                onPressed: () {
                                  bool requiresDelivery = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull?.showShippingSegment == "Yes";
                                  if (requiresDelivery) {
                                    String? currentId = provider.selectedDeliveryLocationId?.trim();
                                    bool isInvalid = currentId == null || currentId.isEmpty || currentId == "0" || currentId.toLowerCase() == "null";
                                    if (isInvalid) {
                                      Fluttertoast.showToast(msg: "Please choose your delivery location");
                                      return;
                                    }
                                  }
                                  final profileResult = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull;
                                  final subtotalVal = double.tryParse(provider.subTotal) ?? 0.0;
                                  if (profileResult?.restrictOnMinOrderAmountNotReached == "Yes") {
                                    final minAmt = double.tryParse(profileResult?.minimumOrderAmount ?? "0") ?? 0.0;
                                    if (minAmt - subtotalVal > 0.0) {
                                      _showOrderAmountDialog(context, CommonMethods.decodeHtmlEntities(profileResult?.minOrderNotificationText ?? "Minimum order amount not reached.", stripTags: true));
                                      return;
                                    }
                                  }
                                  if (profileResult?.maxOrderUnlimited == "No" && profileResult?.restrictOnMaxOrderAmountReached == "Yes") {
                                    final maxAmt = double.tryParse(profileResult?.maxOrderAmount ?? "0") ?? 0.0;
                                    if (subtotalVal > maxAmt) {
                                      _showOrderAmountDialog(context, CommonMethods.decodeHtmlEntities(profileResult?.maxOrderNotificationText ?? "Maximum order amount reached.", stripTags: true));
                                      return;
                                    }
                                  }
                                  provider.nextStep();
                                  if (provider.errorMessage.isNotEmpty) {
                                    Fluttertoast.showToast(msg: provider.errorMessage);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: provider.companyId == "2" ? AppTheme.primaryColor : AppTheme.primaryButtonColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 8.w),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text("Next", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold), maxLines: 1),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
                                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.sp),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Stabilization Overlay
        if (provider.isStabilizing)
          Container(
            color: Colors.white.withValues(alpha: 0.8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3.w,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Updating prices...",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isDiscount = false, bool isBlueValue = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: isDiscount
                      ? AppTheme.redColor
                      : (isBlueValue
                          ? AppTheme.primaryColor
                          : AppTheme.darkBlue),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CheckoutProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ClearCartDialog(
        onClose: () => Navigator.pop(dialogContext),
        onClear: () async {
          // 1. Close dialog FIRST
          Navigator.pop(dialogContext);

          // 2. Perform Clear Action
          await provider.clearCart();

          // 3. Force Update Dashboard Provider & Navigate
          if (context.mounted) {
            final dashboardProvider = context.read<DashboardProvider>();

            // Update global cart count to 0
            dashboardProvider.setCartCount("0");

            // Reset to Home Tab
            dashboardProvider.setIndex(0);

            // Trigger Full Refresh
            dashboardProvider.init();

            // Navigate to Dashboard (Home) to refresh state
            context.go(AppRoutes.dashboard);
          }
        },
      ),
    );
  }

  void _showOrderAmountDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order Amount",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Icon(Icons.close, color: Colors.grey, size: 20.sp),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryButtonColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r)),
                  ),
                  child: Text("OK",
                      style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../config/routes/app_routes.dart';

import '../../../core/utils/common_methods.dart';
import '../../providers/cart_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/cart_item_widget.dart';
import 'widgets/delivery_location_dialog.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../../data/models/delivery_location_response.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    print("DEBUG: CartScreen initState called");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCartDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<DashboardProvider>().refreshDashboard();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppTheme.lightGrayBg, // Light background
      appBar: AppBar(
        title: const Text(
          "My Cart",
          style: TextStyle(color: Colors.white),
        ),
        elevation: 4, // 👈 controls shadow intensity
        shadowColor: Colors.black.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: AppTheme.backIconSize(context)),
                onPressed: () {
                  context.read<DashboardProvider>().refreshDashboard();
                  context.pop();
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          Consumer<CartProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.cartItems.isEmpty) {
                return const SizedBox.shrink(); // Overlay handles loading
              }

              if (provider.cartItems.isEmpty) {
                if (provider.errorMsg != null && provider.errorMsg!.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.sp),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                          SizedBox(height: 10.h),
                          Text(
                            provider.errorMsg!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.sp, color: Colors.red),
                          ),
                          SizedBox(height: 20.h),
                          ElevatedButton(
                            onPressed: () => provider.fetchCartDetails(),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 60.sp, color: AppTheme.hintColor),
                      SizedBox(height: 10.h),
                      Text("Your cart is empty",
                          style: TextStyle(
                              fontSize: 18.sp, color: AppTheme.hintColor)),
                      SizedBox(height: 20.h),
                      ElevatedButton(
                          onPressed: () {
                            context.read<DashboardProvider>().refreshDashboard();
                            context.pop();
                          },
                          child: const Text("Start Shopping")),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), // Scroll handled by SingleChildScrollView
                            itemCount: provider.cartItems.length,
                            itemBuilder: (context, index) {
                              return CartItemWidget(
                                  item: provider.cartItems[index]);
                            },
                          ),

                          SizedBox(height: 10.h),

                          // Delivery Location Section
                          if (provider.cartResult?.showShippingSegment == "Yes" && provider.deliveryLocations.isNotEmpty)
                            Container(
                              color: AppTheme.white,
                              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                              margin: EdgeInsets.only(bottom: 10.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Shipping",
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    provider.shippingSegmentHeading,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (provider.shippingSegmentText.isNotEmpty) ...[
                                    SizedBox(height: 4.h),
                                    Text(
                                      provider.shippingSegmentText,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppTheme.hintColor,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 5.h),
                                  Text(
                                    "Delivery Location",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black87,
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
                                        borderRadius: BorderRadius.circular(5.r),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              provider.selectedDeliveryLocationId == null
                                                  ? "Select Delivery Location"
                                                  : () {
                                                      final selectedLoc = provider.deliveryLocations.firstWhere(
                                                          (loc) => loc.deliveryLocationId == provider.selectedDeliveryLocationId,
                                                          orElse: () => DeliveryLocationResult());
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
                                          Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
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
                                          text: "Selected Delivery Location: ",
                                          style: TextStyle(fontSize: 13.sp, color: AppTheme.primaryColor),
                                          children: [
                                            TextSpan(
                                              text: displayText,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),

                          // Price Breakdown Section (Mirroring ShoppingCartFragment layout)
                          Container(
                            color: AppTheme.white,
                            padding: EdgeInsets.all(15.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sub-Total",
                                  style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkGrayColor),
                                ),
                                _buildPriceRow(
                                    provider.subTotalHeading,
                                    CommonMethods.setPriceFormatString(
                                        provider.subTotal)),

                                // Individual Tax Rows
                                if ((double.tryParse(provider.taxTotal) ?? 0) >
                                    0)
                                  _buildPriceRow(
                                      "GST :",
                                      CommonMethods.setPriceFormatString(
                                          provider.taxTotal)),
                                if ((double.tryParse(provider.levy) ?? 0) > 0)
                                  _buildPriceRow(
                                      "Levy :",
                                      CommonMethods.setPriceFormatString(
                                          provider.levy)),
                                if ((double.tryParse(provider.wet) ?? 0) > 0)
                                  _buildPriceRow(
                                      "WET :",
                                      CommonMethods.setPriceFormatString(
                                          provider.wet)),

                                if (double.tryParse(provider.discount) !=
                                        null &&
                                    double.parse(provider.discount) > 0)
                                if (double.tryParse(provider.couponDiscount) !=
                                        null &&
                                    double.parse(provider.couponDiscount) > 0)
                                  _buildPriceRow(
                                      "Coupon (${provider.couponName})",
                                      "- ${CommonMethods.setPriceFormatString(provider.couponDiscount)}",
                                      color: AppTheme.successGreen),
                                if ((double.tryParse(provider.deliveryCharge) ??
                                            0) >
                                        0 ||
                                    (double.tryParse(provider
                                                .locationDeliveryCharge) ??
                                            0) >
                                        0)
                                  _buildPriceRow(
                                      "Shipping :",
                                      CommonMethods.setPriceFormatString((double.parse(provider.deliveryCharge) +
                                              double.parse(provider
                                                  .locationDeliveryCharge))
                                          .toStringAsFixed(CommonMethods.decimalDigits))),
                                if ((double.tryParse(provider.suppliersExceededCharge) ??
                                        0) >
                                    0)
                                  _buildPriceRow(
                                      "Addnl. Supplier Charge :",
                                      CommonMethods.setPriceFormatString(
                                          provider.suppliersExceededCharge)),

                                Divider(height: 20.h, thickness: 1),
                                Text(
                                  "Grand Total",
                                  style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkGrayColor),
                                ),
                                _buildPriceRow(
                                    provider.totalHeading,
                                    CommonMethods.setPriceFormatString(
                                        provider.totalAmount),
                                    isBold: true,
                                    size: 16.sp),
                              ],
                            ),
                          ),

                          // Minimum/Max Order Notifications (Logic from Fragment)
                          Builder(builder: (context) {
                            final cartResult = provider.cartResult;
                            final subtotalVal = double.tryParse(provider.subTotal) ?? 0.0;
                            final minAmt = double.tryParse(cartResult?.minOrderAmount ?? "0") ?? 0.0;
                            final maxAmt = double.tryParse(cartResult?.maxOrderAmount ?? "0") ?? 0.0;
                            String? warningText;

                            // Show Min warning if subtotal < min (even if restrict is No)
                            if (minAmt > 0 && subtotalVal < minAmt) {
                              warningText = CommonMethods.decodeHtmlEntities(cartResult?.minOrderNotificationText, stripTags: true);
                            } 
                            // Show Max warning if subtotal > max (even if restrict is No)
                            else if (cartResult?.maxOrderUnlimited == "No" && subtotalVal > maxAmt) {
                              warningText = CommonMethods.decodeHtmlEntities(cartResult?.maxOrderNotificationText, stripTags: true);
                            }

                            if (warningText == null || warningText.isEmpty) return const SizedBox.shrink();

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                              child: Center(
                                child: Text(
                                  warningText,
                                  style: TextStyle(
                                    color: AppTheme.redColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }),

                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.shadowBlack,
                            blurRadius: 4,
                            offset: Offset(0, -2)),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                          ),
                          onPressed: () {
                            // Native app checks showShippingSegment == "Yes" to enforce delivery selection
                            bool requiresDelivery = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull?.showShippingSegment == "Yes";
                            
                            if (requiresDelivery) {
                              String? currentId = provider.selectedDeliveryLocationId?.trim();
                              bool isInvalid = currentId == null || 
                                               currentId.isEmpty || 
                                               currentId == "0" || 
                                               currentId.toLowerCase() == "null";
                                               
                              // If it's invalid, block checkout, exactly like Native Android.
                              if (isInvalid) {
                                Fluttertoast.showToast(msg: "Please choose your delivery location");
                                return;
                              }
                            }
                            
                            context.push(AppRoutes.checkout);
                          },
                          child: Text(
                            "PROCEED TO CHECKOUT",
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Container(
                  color: Colors.black54,
                  child: Center(
                    child: SizedBox(
                      width: 100.w,
                      height: 100.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomLoaderWidget(size: 100.w),
                          Text(
                            "Please Wait",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, double? size, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: size ?? 14.sp,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: AppTheme.darkGrayColor)),
          Text(value,
              style: TextStyle(
                  fontSize: size ?? 14.sp,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? AppTheme.textColor)),
        ],
      ),
    );
  }
}

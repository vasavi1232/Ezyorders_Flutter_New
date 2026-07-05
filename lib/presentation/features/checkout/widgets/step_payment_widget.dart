import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../providers/checkout_provider.dart';
import '../../../../core/constants/app_messages.dart';
import '../../../../core/utils/common_methods.dart';

class StepPaymentWidget extends StatefulWidget {
  const StepPaymentWidget({super.key});

  @override
  State<StepPaymentWidget> createState() => _StepPaymentWidgetState();
}

class _StepPaymentWidgetState extends State<StepPaymentWidget> {
  @override
  void initState() {
    super.initState();
    // Payment method default selection is now handled in CheckoutProvider._loadPaymentMethods()
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckoutProvider>();

    return Column(
      children: [
        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(16.w),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Order Summary" Header
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: AppTheme.primaryColor,
                        size: 20.sp), // Document Icon
                    SizedBox(width: 8.w),
                    Text(
                      "Order Summary",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor, // Blue
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Main Card
                Container(
                  padding: EdgeInsets.all(15.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.r),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          blurRadius: 5,
                          spreadRadius: 1),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Additional Information
                      _buildSectionTitle("Additional Information"),
                      SizedBox(height: 5.h),
                      Text("Order Reference Number",
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 5.h),
                      TextFormField(
                        controller: provider.orderReferenceController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: "Enter Reference Number",
                          hintStyle: TextStyle(
                              color: AppTheme.hintColor, fontSize: 13.sp),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.r),
                            borderSide: BorderSide(color: AppTheme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.r),
                            borderSide: BorderSide(color: AppTheme.borderColor),
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text("Order Notes",
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 5.h),
                      TextFormField(
                        controller: provider.orderNotesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              "Notes about your order, e.g special notes for delivery",
                          hintStyle: TextStyle(
                              color: AppTheme.hintColor, fontSize: 13.sp),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.r),
                            borderSide: BorderSide(color: AppTheme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.r),
                            borderSide: BorderSide(color: AppTheme.borderColor),
                          ),
                          contentPadding: EdgeInsets.all(10.w),
                        ),
                      ),
                      SizedBox(height: 15.h),

                      // Use Coupon Code
                      _buildSectionTitle("Use Coupon Code"),
                      SizedBox(height: 5.h),
                      Text("Enter your coupon code if you have one.",
                          style: TextStyle(
                              fontSize: 13.sp, color: Colors.grey.shade700)),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 40.h,
                              child: TextFormField(
                                controller: provider.couponController,
                                onChanged: (val) {
                                  if (val.trim().isEmpty) {
                                    provider.clearError();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "Enter Coupon Code",
                                  hintStyle: TextStyle(
                                      color: AppTheme.hintColor,
                                      fontSize: 13.sp),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 10.w),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.r),
                                    borderSide:
                                        BorderSide(color: AppTheme.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.r),
                                    borderSide:
                                        BorderSide(color: AppTheme.borderColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 40.h,
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: provider.couponController,
                                builder: (context, value, child) {
                                  final isCouponEmpty =
                                      value.text.trim().isEmpty;
                                  return ElevatedButton(
                                    onPressed: (provider.isLoading ||
                                            isCouponEmpty)
                                        ? null
                                        : () async {
                                            bool success =
                                                await provider.applyCoupon();
                                            if (!context.mounted) return;
                                            if (success) {
                                              CommonMethods.showSuccessPopup(
                                                context,
                                                title: "Coupon",
                                                subTitle: "Coupon Applied",
                                                message: AppMessages
                                                    .couponAppliedSuccessfully,
                                              );
                                            } else {
                                              CommonMethods.showErrorPopup(
                                                context,
                                                title: "Coupon",
                                                subTitle: "Coupon Not Applied",
                                                message: provider.errorMessage,
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCouponEmpty
                                          ? Colors.grey.shade400
                                          : AppTheme
                                              .tealColor, // Grey or Orange
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.r)),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text("Apply",
                                            style: TextStyle(fontSize: 14.sp)),
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                      ),

                      SizedBox(height: 15.h),

                      // Order Details (Styled Match)
                      _buildSectionTitle("Order Details"),
                      SizedBox(height: 10.h),

                      // Dynamic Sub-Total Row
                      _buildSummaryRow(
                          provider.subTotalHeading,
                          CommonMethods.setPriceFormatString(provider.subTotal),
                          isBlueValue: true),

                      if ((double.tryParse(provider.shippingCharge) ?? 0) > 0)
                        _buildSummaryRow(
                            "Shipping :",
                            CommonMethods.setPriceFormatString(provider.shippingCharge),
                            isBlueValue: true),

                      if ((double.tryParse(provider.supplierCharge) ?? 0) > 0)
                        _buildSummaryRow(
                            "Addnl. Supplier Charge :",
                            CommonMethods.setPriceFormatString(
                                provider.supplierCharge),
                            isBlueValue: true),

                      // Levy (Conditional)
                      Builder(builder: (context) {
                        final profile = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull;
                        final showLevy = profile?.showLevy == "Yes";
                        final includeLevy = profile?.includeLevyInPriceCalculation == "No";
                        final hasLevy = (double.tryParse(provider.levy) ?? 0) > 0;

                        if (showLevy && includeLevy && hasLevy) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 0.h),
                            child: _buildSummaryRow(
                                "Levy :",
                                CommonMethods.setPriceFormatString(provider.levy),
                                isBlueValue: true),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // WET (Conditional)
                      Builder(builder: (context) {
                        final profile = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull;
                        final showWet = profile?.showWet == "Yes";
                        final includeWet = profile?.includeWetInPriceCalculation == "No";
                        final hasWet = (double.tryParse(provider.wet) ?? 0) > 0;

                        if (showWet && includeWet && hasWet) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 0.h),
                            child: _buildSummaryRow(
                                "WET :",
                                CommonMethods.setPriceFormatString(provider.wet),
                                isBlueValue: true),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // GST (Conditional)
                      Builder(builder: (context) {
                        final profile = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull;
                        final showPriceIncGst = profile?.showPriceIncludingGst ?? "No";
                        final showGstInCart = profile?.showGstInCart ?? "No";
                        final taxTotalVal = double.tryParse(provider.taxTotal) ?? 0;

                        if (taxTotalVal > 0 || (showPriceIncGst == "No" && showGstInCart == "Yes")) {
                          return _buildSummaryRow(
                              "GST :",
                              CommonMethods.setPriceFormatString(
                                  provider.taxTotal),
                              isBlueValue: true);
                        }
                        return const SizedBox.shrink();
                      }),

                      if ((double.tryParse(provider.couponDiscount) ?? 0) > 0)
                        _buildSummaryRow("Coupon (${provider.couponName})",
                            "-${CommonMethods.setPriceFormatString(provider.couponDiscount)}",
                            isDiscount: true),

                      SizedBox(height: 10.h),

                      // Dynamic Total Row
                      _buildSummaryRow(
                          provider.totalHeading,
                          CommonMethods.setPriceFormatString(
                              provider.totalAmount),
                          isBlueValue: true),

                      SizedBox(height: 15.h),

                      // Payment Method
                      _buildSectionTitle("Payment Method"),
                      SizedBox(height: 5.h),
                      Text("Choose Your Payment Method",
                          style: TextStyle(
                              fontSize: 13.sp, color: Colors.grey.shade700)),
                      SizedBox(height: 5.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme
                                  .blackColor), // Screenshot looks like black border
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: provider.paymentMethod.isNotEmpty &&
                                    provider.availablePaymentMethods
                                        .contains(provider.paymentMethod)
                                ? provider.paymentMethod
                                : (provider.availablePaymentMethods.isNotEmpty
                                    ? provider.availablePaymentMethods[0]
                                    : null), // Safe fallback
                            icon: Icon(Icons.keyboard_arrow_down),
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold),
                            items: provider.availablePaymentMethods
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                provider.selectPaymentMethod(val);
                              }
                            },
                            hint: Text("Select Payment Method",
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
        ),

        // Sticky Bottom Navigation (Shadow + Buttons)
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back Button
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: SizedBox(
                    height: 45.h,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.previousStep();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkGrayColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.r)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios,
                              size: 16.sp, color: Colors.white),
                          SizedBox(width: 5.w),
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Back",
                                  maxLines: 1,
                                  textScaler: const TextScaler.linear(1.0),
                                  style: TextStyle(
                                      fontSize: 14.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Dynamic Step Indicator
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("${provider.currentStep + 1}/${provider.totalSteps}",
                        maxLines: 1,
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              // Place Order Button
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: SizedBox(
                    height: 45.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!provider.isCompanyActive) {
                          CommonMethods.showCompanyInActiveDialog(
                              context, provider.companyName);
                          return;
                        }
  
                        if (provider.validatePaymentStep()) {
                          if (provider.isPreviewEnabled) {
                            provider.nextStep();
                          } else {
                            provider.placeOrder(context);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text(AppMessages.pleaseSelectPaymentMethod)));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.companyId == "2"
                            ? AppTheme.primaryColor
                            : AppTheme.primaryButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.r)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: const TextScaler.linear(1.0), // 🔒 ignore system font size
                            ),
                            child: Text(
                              provider.isPreviewEnabled
                                  ? "Review Order"
                                  : (provider.paymentMethod == "Cash on Delivery" ||
                                          provider.paymentMethod == "COD" ||
                                          provider.paymentMethod.isEmpty
                                      ? "Submit Order"
                                      : "Pay Order"),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor, // Blue
      ),
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
                  color: AppTheme.darkGrayColor,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: isDiscount
                      ? AppTheme.redColor
                      : (isBlueValue ? AppTheme.primaryColor : Colors.black),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

}

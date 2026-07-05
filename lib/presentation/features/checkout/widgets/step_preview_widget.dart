import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../providers/checkout_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../widgets/gst_message_widget.dart';
import '../../../widgets/specials_tooltip.dart';

class StepPreviewWidget extends StatelessWidget {
  const StepPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckoutProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final bool showSoldAs = dashboardProvider.profileResponse?.results?.firstOrNull?.showSoldAs == "Yes";
    
    // Use cartResult.brands for grouped items, fallback to cartItems if empty
    final brands = provider.cartResult?.brands;
    final flatItems = provider.cartItems;
    final hasBrands = brands != null && brands.isNotEmpty;

    return Column(
      children: [
        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GstMessageWidget(padding: EdgeInsets.zero),
                SizedBox(height: 10.h),
                // 1. Order Details Card
                _buildCard(
                  context,
                  title: "Order Details",
                  onEdit: () => provider.goToStep(0), // Go to Cart
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Items Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Items",
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600)),
                          Text("Qty",
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900)),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      const Divider(),

                      // Grouped Items (by Brand) OR Flat list
                      if (hasBrands)
                        ...brands.map((brand) {
                          if (brand == null || brand.products == null) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.h),
                              Text(
                                brand.brandName ?? "Unknown Vendor",
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800),
                              ),
                              SizedBox(height: 5.h),
                              Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: AppTheme.borderColor),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Column(
                                  children: brand.products!.map((product) {
                                    if (product == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return _ProductPreviewItem(
                                      product: product,
                                      showSoldAs: showSoldAs,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          );
                        })
                      else
                        ...flatItems.map((item) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.h),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(item.title ?? "",
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor)),
                                  ),
                                   Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("${item.qty}",
                                          style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor)),
                                      if (showSoldAs && item.orderedAs != null && item.orderedAs!.isNotEmpty)
                                        Text(
                                          item.orderedAs!,
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ]),
                          );
                        }),

                      SizedBox(height: 15.h),
                      const Divider(),
                      SizedBox(height: 10.h),

                      // Price Breakdown (Styled Match)
                      // Dynamic Sub-Total Row
                      _buildSummaryRow(
                          provider.subTotalHeading,
                          CommonMethods.setPriceFormatString(provider.subTotal),
                          isBlueValue: true),

                      // Shipping (Native Parity)
                      if (context.read<DashboardProvider>().profileResponse?.results?.firstOrNull?.showShippingSegment == "Yes" &&
                          (double.tryParse(provider.shippingCharge) ?? 0) > 0)
                        _buildSummaryRow(
                            "Shipping :",
                            CommonMethods.setPriceFormatString(provider.shippingCharge),
                            isBlueValue: true),

                      // Extra Charges if any
                      if (context.read<DashboardProvider>().profileResponse?.results?.firstOrNull?.showShippingSegment != "Yes" &&
                          (double.tryParse(provider.shippingCharge) ?? 0) > 0)
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
                        final profile = dashboardProvider.profileResponse?.results?.firstOrNull;
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

                      _buildSummaryRow(
                          provider.totalHeading,
                          CommonMethods.setPriceFormatString(
                              provider.totalAmount),
                          isBlueValue: true),
                    ],
                  ),
                ),

                if (provider.orderNotesController.text.trim().isNotEmpty || provider.orderReferenceController.text.trim().isNotEmpty) ...[
                  SizedBox(height: 15.h),
                  _buildCard(
                    context,
                    title: "Additional Information",
                    onEdit: () => provider.goToStep(2), // Go to Payment where it's edited
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.orderReferenceController.text.trim().isNotEmpty) ...[
                          Text("Order Reference Number",
                              style:
                                  TextStyle(fontSize: 12.sp, color: Colors.grey)),
                          SizedBox(height: 2.h),
                          Text(
                            provider.orderReferenceController.text.trim(),
                            style: TextStyle(
                                fontSize: 13.sp,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                          if (provider.orderNotesController.text.trim().isNotEmpty)
                            SizedBox(height: 10.h),
                        ],
                        if (provider.orderNotesController.text.trim().isNotEmpty) ...[
                          Text("Order Notes",
                              style:
                                  TextStyle(fontSize: 12.sp, color: Colors.grey)),
                          SizedBox(height: 2.h),
                          Text(
                            provider.orderNotesController.text.trim(),
                            style: TextStyle(
                                fontSize: 13.sp,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 15.h),

                // 2. Address Details Card
                _buildCard(
                  context,
                  title: "Address Details",
                  onEdit: () => provider.goToStep(1), // Go to Address
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Delivery Address",
                          style:
                              TextStyle(fontSize: 13.sp, color: Colors.grey)),
                      SizedBox(height: 2.h),
                      Text(
                        _formatAddress(
                          provider.isNewAddressChecked ? provider.shipFirstNameController.text : provider.billFirstNameController.text,
                          provider.isNewAddressChecked ? provider.shipLastNameController.text : provider.billLastNameController.text,
                          provider.isNewAddressChecked ? provider.shipStreetController.text : provider.billStreetController.text,
                          provider.isNewAddressChecked ? provider.shipStreet2Controller.text : provider.billStreet2Controller.text,
                          provider.isNewAddressChecked ? provider.shipCityController.text : provider.billCityController.text,
                          provider.isNewAddressChecked ? provider.shipStateController.text : provider.billStateController.text,
                          provider.isNewAddressChecked ? provider.shipPostCodeController.text : provider.billPostCodeController.text,
                        ),
                        style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10.h),
                      Text("Billing Address",
                          style:
                              TextStyle(fontSize: 13.sp, color: Colors.grey)),
                      SizedBox(height: 2.h),
                      Text(
                        _formatAddress(
                          provider.billFirstNameController.text,
                          provider.billLastNameController.text,
                          provider.billStreetController.text,
                          provider.billStreet2Controller.text,
                          provider.billCityController.text,
                          provider.billStateController.text,
                          provider.billPostCodeController.text,
                        ),
                        style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15.h),

                // 3. Payment Details Card
                _buildCard(
                  context,
                  title: "Payment Details",
                  onEdit: () => provider.goToStep(2), // Go to Payment
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Payment Method",
                          style:
                              TextStyle(fontSize: 12.sp, color: Colors.grey)),
                      SizedBox(height: 2.h),
                      Text(
                        provider.paymentMethod.isNotEmpty
                            ? provider.paymentMethod
                            : "Not Selected",
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                    height:
                        30.h), // Extra space for scrolling above sticky footer
              ],
            ),
          ),
        ),

        // Sticky Bottom Footer
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
              // Back Button (Matching other steps)
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
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios,
                              color: Colors.white, size: 16.sp),
                          SizedBox(width: 5.w),
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("Back",
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold)),
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

              // Submit Order Button
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: SizedBox(
                    height: 45.h,
                    child: ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () {
                              if (!provider.isCompanyActive) {
                                CommonMethods.showCompanyInActiveDialog(
                                    context, provider.companyName);
                                return;
                              }
                              provider.placeOrder(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.companyId == "2"
                            ? AppTheme.primaryColor
                            : AppTheme.primaryButtonColor, // Dynamic Theme Color
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        elevation: 2,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  provider.paymentMethod == "Cash on Delivery" ||
                                          provider.paymentMethod == "COD" ||
                                          provider.paymentMethod.isEmpty
                                      ? "Submit Order"
                                      : "Pay Order",
                                  style: TextStyle(
                                      fontSize: 14.sp, fontWeight: FontWeight.bold),
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

  String _formatAddress(String fName, String lName, String street, String street2,
      String city, String state, String zip) {
    List<String> parts = [];
    String name = "$fName $lName".trim();
    if (name.isNotEmpty) parts.add(name);
    // Logic matches Android: "rajat mehra, malviya nagar, jaipur, jaipur rajasthan 302017"
    if (street.isNotEmpty) parts.add(street);
    if (street2.isNotEmpty) parts.add(street2);
    if (city.isNotEmpty) parts.add(city);
    String stateZip = "$state $zip".trim();
    if (stateZip.isNotEmpty) parts.add(stateZip);

    if (parts.isEmpty) return "Not provided";
    return parts.join(", ");
  }

  Widget _buildCard(BuildContext context,
      {required String title,
      required VoidCallback onEdit,
      required Widget child}) {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.r),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 4,
              spreadRadius: 1),
        ],
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor, // Blue
                ),
              ),
              InkWell(
                onTap: onEdit,
                child: Icon(Icons.edit_outlined,
                    color: AppTheme.primaryColor, size: 20.sp),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBlueValue = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDiscount
                  ? Colors.red
                  : (isBlueValue ? AppTheme.primaryColor : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPreviewItem extends StatefulWidget {
  final dynamic product;
  final bool showSoldAs;

  const _ProductPreviewItem({required this.product, required this.showSoldAs});

  @override
  State<_ProductPreviewItem> createState() => _ProductPreviewItemState();
}

class _ProductPreviewItemState extends State<_ProductPreviewItem> {
  final GlobalKey _percentageStripKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final showSoldAs = widget.showSoldAs;

    return Padding(
      padding: EdgeInsets.all(8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title ?? "",
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor),
                ),
                SizedBox(height: 4.h),
                GestureDetector(
                  onTapDown: (details) {
                    final String dId = (product.specialId ?? product.discountId ?? "").trim();
                    final String dName = (product.specialName ?? product.discountName ?? "").trim();
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
                  },
                  child: Row(
                    children: [
                      if (() {
                        double n = double.tryParse(product.normalPrice ?? "0") ?? 0;
                        double s = double.tryParse(product.salePrice ?? "0") ?? 0;
                        return s > 0 && (n - s) > 0.01;
                      }()) ...[
                        Text(
                          CommonMethods.setPriceFormatString(product.normalPrice),
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.sp,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          CommonMethods.setPriceFormatString(product.salePrice),
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          key: _percentageStripKey,
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppTheme.redColor,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: Text(
                            "-${CommonMethods.calculateDiscount(product.normalPrice ?? "0", product.salePrice ?? "0")}%",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else
                        Text(
                          CommonMethods.setPriceFormatString(
                              (double.tryParse(product.salePrice ?? "0") ?? 0) > 0
                                  ? product.salePrice
                                  : product.normalPrice),
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${product.qty}",
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor),
              ),
              if (showSoldAs && product.orderedAs != null && product.orderedAs!.isNotEmpty)
                Text(
                  product.orderedAs!,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

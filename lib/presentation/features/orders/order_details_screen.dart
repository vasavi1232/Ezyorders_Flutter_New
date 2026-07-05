import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_theme.dart';
import '../../../config/routes/app_routes.dart';
import '../../../core/utils/common_methods.dart';
import '../../../data/models/order_models.dart';
import '../../../data/models/profile_models.dart';
import '../../providers/orders_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/specials_tooltip.dart';
import 'widgets/custom_confirm_dialog.dart';
import 'widgets/custom_success_dialog.dart';
import 'widgets/custom_error_dialog.dart';
import 'widgets/add_to_cart_success_dialog.dart';
import 'widgets/custom_pdf_dialog.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderHistoryResult order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().fetchOrderDetails(
            orderId: widget.order.orderId.toString(),
          );
    });
  }

  Future<void> _handleCancelOrder() async {
    final bool? confirm = await _showConfirmDialog(
      title: "Cancel Order Confirmation",
      orderId: widget.order.refNo ?? "",
      content: "Do you want to cancel this order?",
      confirmText: "Cancel Order",
      confirmColor: AppTheme.redColor,
    );

    if (confirm == true && mounted) {
      final ordersProvider = context.read<OrdersProvider>();
      final success = await ordersProvider.cancelOrder(
        orderId: widget.order.orderId.toString(),
      );
      if (success && mounted) {
        context.read<OrdersProvider>().fetchOrders(isRefresh: true);
        Navigator.pop(context); // Go back to list
      } else if (mounted) {
        _showErrorDialog("Cancel Failed", ordersProvider.actionError ?? "Unknown error occurred");
      }
    }
  }

  Future<void> _handleDuplicateOrder() async {
    final dashboardProvider = context.read<DashboardProvider>();
    final contentText = dashboardProvider.profileResponse?.results?.firstOrNull?.replicateOrderConfirmationText ??
        "Do you want to duplicate this order?";

    final bool? confirm = await _showConfirmDialog(
      title: "Duplicate Order Confirmation",
      orderId: widget.order.refNo ?? "",
      content: contentText,
      confirmText: "Duplicate",
      confirmColor: AppTheme.primaryColor,
    );

    if (confirm == true && mounted) {
      final ordersProvider = context.read<OrdersProvider>();
      final newOrderId = await ordersProvider.duplicateOrder(
        oldOrderId: widget.order.orderId.toString(),
      );
      if (newOrderId != null && mounted) {
        _showSuccessDialog("Order Duplicated Successfully", "#$newOrderId", onOk: () {
          if (mounted) {
            context.read<OrdersProvider>().fetchOrders(isRefresh: true);
            Navigator.pop(context);
          }
        });
      } else if (mounted) {
        _showErrorDialog("Duplicate Order Failed", ordersProvider.actionError ?? "Unknown error occurred");
      }
    }
  }

  Future<void> _handleReorder() async {
    final dashboardProvider = context.read<DashboardProvider>();
    final contentText = dashboardProvider.profileResponse?.results?.firstOrNull?.reorderConfirmationText ??
        "You are Re-Ordering the same products.\nProducts price will update with the current price.";

    final bool? confirm = await _showConfirmDialog(
      title: "Re-Order Confirmation",
      orderId: widget.order.refNo ?? "",
      content: contentText,
      confirmText: "Re-Order",
      confirmColor: AppTheme.tealColor,
      confirmButtonColor: AppTheme.primaryButtonColor,
    );

    if (confirm == true && mounted) {
      final ordersProvider = context.read<OrdersProvider>();
      final success = await ordersProvider.reorderOrder(
        oldOrderId: widget.order.orderId.toString(),
      );
      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AddToCartSuccessDialog(
            onClosed: () async {
              if (mounted) {
                final authProvider = context.read<AuthProvider>();
                final checkoutProvider = context.read<CheckoutProvider>();
                final dashboardProvider = context.read<DashboardProvider>();

                await checkoutProvider.initCheckout(
                    authProvider.user?.accessToken ?? "",
                    authProvider.user?.customerId ?? "",
                    stabilize: true);
                
                dashboardProvider.setCartCount(CommonMethods.cartCount);

                if (mounted) {
                  while (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  context.push(AppRoutes.checkout, extra: {'initialStep': 0});
                }
              }
            },
          ),
        );
      } else if (mounted) {
        _showErrorDialog("Re-Order Failed", ordersProvider.actionError ?? "Unknown error occurred");
      }
    }
  }

  void _handleDownload() {
    if (widget.order.pdfFile != null && widget.order.pdfFile!.isNotEmpty && widget.order.pdfFile != "null") {
      showDialog(
        context: context,
        builder: (ctx) => CustomPdfDialog(
          pdfUrl: widget.order.pdfFile!,
          orderId: widget.order.refNo ?? "Unknown",
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invoice not available yet.")));
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String orderId,
    required String content,
    required String confirmText,
    required Color confirmColor,
    Color? confirmButtonColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CustomConfirmDialog(
        title: title,
        orderId: orderId,
        content: content,
        confirmText: confirmText,
        confirmColor: confirmColor,
        confirmButtonColor: confirmButtonColor,
      ),
    );
  }

  void _showSuccessDialog(String title, String orderId, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (ctx) => CustomSuccessDialog(
        title: title,
        orderId: orderId,
        content: "",
        onOk: onOk,
      ),
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => CustomErrorDialog(
        title: title,
        content: content,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "null") return "";
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == "null") return "";
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('HH:mm a').format(dateTime);
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.white, size: AppTheme.backIconSize(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
      body: Stack(
        children: [
          Consumer2<OrdersProvider, DashboardProvider>(
            builder: (context, provider, dashboardProvider, child) {
              if (provider.isLoading && provider.orderDetails == null) {
                return const SizedBox.shrink();
              }

              final details = provider.orderDetails;
              if (details == null) {
                return const Center(child: Text("Failed to load order details"));
              }

              final profile = dashboardProvider.profileResponse?.results?.firstOrNull;

              return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(widget.order),
                  const Divider(height: 1),
                  _buildSectionTitle("Item Details"),
                  const Divider(height: 1),
                  _buildProductsList(details.results ?? []),
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: _buildOrderSummary(widget.order),
                  ),
                  _buildExpandableSection("Address Details", _buildAddressInfo(widget.order)),
                  _buildExpandableSection("Payment Details", _buildPaymentDetails(widget.order)),
                  if (widget.order.remarks != null && widget.order.remarks!.isNotEmpty && widget.order.remarks != "null")
                    _buildExpandableSection("Order Notes", Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Text(widget.order.remarks!, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700)),
                    )),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: _buildActionButtonsGrid(widget.order, profile),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          );
        },
      ),
      Consumer<OrdersProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomLoaderWidget(size: 80.w),
                      SizedBox(height: 16.h),
                      Text(
                        "Please Wait",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 15.sp,
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
);
}

  Widget _buildHeader(OrderHistoryResult order) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order ID : #${order.refNo}",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    order.orderStatus ?? "",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: order.orderStatus?.toLowerCase() == "cancelled"
                          ? AppTheme.redColor
                          : AppTheme.successGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.check_circle,
                    color: order.orderStatus?.toLowerCase() == "cancelled"
                        ? AppTheme.redColor
                        : AppTheme.successGreen,
                    size: 18.sp,
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          _buildInfoRow("Order Date :", _formatDate(order.orderDate)),
          SizedBox(height: 4.h),
          _buildInfoRow("Order Time :", _formatTime(order.orderDate)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildProductsList(List<OrderDetailResult> results) {
    return Column(
      children: results.map((result) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: const BoxDecoration(
                color: Color(0xFF0D6EFD), // Bootstrap primary blue
              ),
              child: Text(
                result.brandName ?? "Supplier",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...?result.products?.map((product) => _buildProductItem(product)),
            const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProductItem(OrderProduct product) {
    // Discount Calculation for Red Strip
    final originalPrice = double.tryParse(product.normalPrice ?? "0") ?? 0;
    final promoPrice = double.tryParse(product.salePrice ?? "0") ?? 0;
    final hasDiscount = promoPrice > 0 && promoPrice < originalPrice;
    
    String discountText = "";
    if (hasDiscount) {
      discountText = "-${CommonMethods.calculateDiscount(product.normalPrice, product.salePrice)}%";
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CommonMethods.htmltag(product.productName),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              if (hasDiscount)
                Text(
                  CommonMethods.setPriceFormatString(product.normalPrice),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              if (hasDiscount) SizedBox(width: 8.w),
              Text(
                CommonMethods.setPriceFormatString(hasDiscount ? product.salePrice : product.normalPrice),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: hasDiscount ? AppTheme.redColor : Colors.black,
                ),
              ),
              if (hasDiscount && discountText.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Builder(
                  builder: (tooltipContext) {
                    final bool canShowTooltip = (product.apiSpecialId != null && product.apiSpecialId!.isNotEmpty) || 
                                              (product.specialId != null && product.specialId!.isNotEmpty);

                    final Widget tag = Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.redColor,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                      child: Text(
                        discountText,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );

                    if (!canShowTooltip) return tag;

                    return GestureDetector(
                      onTap: () {
                        final RenderBox box = tooltipContext.findRenderObject() as RenderBox;
                        final Offset offset = box.localToGlobal(Offset.zero);
                        final Rect rect = Rect.fromLTWH(
                          offset.dx,
                          offset.dy,
                          box.size.width,
                          box.size.height,
                        );

                        SpecialsTooltip.show(
                          context,
                          discountId: (product.apiSpecialId != null && product.apiSpecialId!.isNotEmpty) 
                              ? product.apiSpecialId! 
                              : (product.specialId ?? "Special"),
                          discountName: (product.apiSpecialName != null && product.apiSpecialName!.isNotEmpty) 
                              ? product.apiSpecialName! 
                              : (product.specialName ?? ""),
                          targetRect: rect,
                        );
                      },
                      child: tag,
                    );
                  },
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Qty : ${product.quantity}",
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade800),
              ),
              Text(
                "Total : ${CommonMethods.setPriceFormatString(product.subTotal)}",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallInfo("Sold As :", product.soldAs),
              _buildSmallInfo("Ordered As :", product.orderedAs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(String label, String? value) {
    return Row(
      children: [
        Text(
          "$label ",
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        Text(
          value ?? "N/A",
          style: TextStyle(fontSize: 13.sp, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(OrderHistoryResult order) {
    // Labels match checkout logic exactly
    final subTotalLabel = "Sub-Total";
    final subTotalExclLabel = "Ex. Levy, Ex. GST :";
    final levyLabel = "Levy :";
    final wetLabel = "WET :";
    final gstLabel = "GST :";
    final totalLabel = "Grand Total";
    final totalInclLabel = "Inc. Levy, Inc. GST :";

    final double levy = double.tryParse(order.levy ?? "0") ?? 0;
    final double wet = double.tryParse(order.wet ?? "0") ?? 0;
    final double gst = (double.tryParse(order.gst ?? "0") ?? 0) + 
                       (double.tryParse(order.deliveryChargeGst ?? "0") ?? 0);
    
    final delivery = (double.tryParse(order.deliveryCharge ?? "0") ?? 0) + 
                    (double.tryParse(order.deliveryLocationCharge ?? "0") ?? 0);
    final addSupplier = double.tryParse(order.suppliersExceededShippingCharge ?? "0") ?? 0;
    final coupon = double.tryParse(order.couponDiscount ?? "0") ?? 0;

    return Column(
      children: [
        _buildSummaryRow(subTotalLabel, null), // Header only
        _buildSummaryRow(subTotalExclLabel, order.subTotal),
        
        // --- Added Levy and WET before GST ---
        if (levy > 0) _buildSummaryRow(levyLabel, levy.toString()),
        if (wet > 0) _buildSummaryRow(wetLabel, wet.toString()),
        
        _buildSummaryRow(gstLabel, gst.toString()),
        
        if (delivery > 0) _buildSummaryRow("Delivery Charge :", delivery.toString()),
        if (addSupplier > 0) _buildSummaryRow("Additional Supplier Charge :", addSupplier.toString()),
        if (coupon > 0)
          _buildSummaryRow("Coupon Discount :", "-$coupon", valueColor: AppTheme.redColor),
        const Divider(),
        _buildSummaryRow(totalLabel, order.orderAmount, isTotal: true),
        _buildSummaryRow(totalInclLabel, null), // Label only below
      ],
    );
  }

  Widget _buildExpandableSection(String title, Widget content) {
    return Column(
      children: [
        const Divider(height: 1),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            iconColor: AppTheme.primaryColor,
            collapsedIconColor: AppTheme.primaryColor,
            children: [content],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressInfo(OrderHistoryResult order) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressRow("Billing Address :", order.billingAddress),
          SizedBox(height: 12.h),
          _buildAddressRow("Shipping Address :", order.deliveryAddress),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String title, String? address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
        SizedBox(height: 4.h),
        Text(
          CommonMethods.htmltag(address),
          style: TextStyle(fontSize: 13.sp, color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(OrderHistoryResult order) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Text("Payment Method : ", style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
          Text(
            order.paymentType?.replaceAll("COD", "Cash on Delivery") ?? "N/A",
            style: TextStyle(fontSize: 13.sp, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsGrid(OrderHistoryResult order, ProfileResult? profile) {
    final allowCancel = profile?.allowCustomerToCancelOrder == "Yes";
    final isPending = order.orderStatus?.toLowerCase() == "received" || order.orderStatus?.toLowerCase() == "processing";
    final showCancel = allowCancel && isPending;

    final allowDuplicate = profile?.allowCustomersToReplicateOrders == "Yes";
    final allowReorder = profile?.allowCustomerToReorderSameProducts == "Yes";

    List<Widget> buttons = [];
    
    if (allowReorder) {
      buttons.add(_buildGridButton(
        label: "Re-Order",
        color: const Color(0xFFFFB347),
        onTap: _handleReorder,
      ));
    }
    
    if (allowDuplicate) {
      buttons.add(_buildGridButton(
        label: "Duplicate Order",
        color: const Color(0xFF1E3A8A),
        onTap: _handleDuplicateOrder,
      ));
    }

    if (showCancel) {
      buttons.add(_buildGridButton(
        label: "Cancel Order",
        color: const Color(0xFFE4134A),
        onTap: _handleCancelOrder,
      ));
    }

    // Order Confirmation is always shown if PDF exists
    buttons.add(_buildGridButton(
      label: "Order Confirmation",
      color: const Color(0xFF0DCAF0),
      onTap: _handleDownload,
    ));

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 3.8, // Adjusted for button text
        ),
        itemCount: buttons.length,
        itemBuilder: (context, index) => buttons[index],
      ),
    );
  }

  Widget _buildGridButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 48.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String? value,
      {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.grey.shade800,
              ),
            ),
          ),
          if (value != null)
            Text(
              CommonMethods.setPriceFormatString(value),
              style: TextStyle(
                fontSize: isTotal ? 15.sp : 14.sp,
                fontWeight: FontWeight.bold,
                color: valueColor ?? (isTotal ? AppTheme.primaryColor : Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}



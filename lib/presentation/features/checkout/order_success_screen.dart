import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/common_methods.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/send_order_receipt_email_dialog.dart';
import 'widgets/email_confirmation_dialog.dart';

import 'package:lottie/lottie.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../config/routes/app_routes.dart';
import '../../../../core/constants/app_theme.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const OrderSuccessScreen({super.key, required this.orderData});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final checkoutProvider = context.read<CheckoutProvider>();
      checkoutProvider.clearCart(); // Call API to clear cart
      checkoutProvider.fetchOrderSuccessMessage(); // Fetch dynamic message
    });
  }

  void _showSendReceiptDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SendOrderReceiptEmailDialog(
        onSend: (emails) async {
          final success = await context.read<CheckoutProvider>().sendOrderReceipt(
              widget.orderData['order_id'] ?? widget.orderData['refNo'], emails);
          if (success && mounted) {
            showDialog(
              context: context,
              builder: (ctx) => const EmailConfirmationDialog(
                message: "Email has been sent successfully",
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Native Android uses 'refNo' (e.g. #ED00000018) for the displayed Order ID
    final orderId = widget.orderData['refNo'] ??
        widget.orderData['order_id'] ??
        ""; 

    final bool isTabletLandscape = MediaQuery.of(context).size.shortestSide >= 600 &&
        MediaQuery.of(context).orientation == Orientation.landscape;
    final double buttonHeight = isTabletLandscape ? 75.h : 45.h;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Order Success",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button on success screen
      ),
      body: SingleChildScrollView(
        child: Container(
          // Ensure it takes at least the full screen height minus app bar to center content
          constraints: BoxConstraints(
            minHeight: 1.sh - MediaQuery.of(context).padding.top - kToolbarHeight,
          ),
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Blue Circle Icon / Lottie Animation
              SizedBox(
                width: 220.w,
                height: 220.w,
                child: Lottie.asset(
                  'assets/animations/congrats_check.json',
                  repeat: true,
                  reverse: false,
                  animate: true,
                ),
              ),

              // Main Message - Displayed from Backend
              Consumer<CheckoutProvider>(
                builder: (context, checkoutProvider, child) {
                  final rawMessage = checkoutProvider.orderSuccessContent.isNotEmpty
                      ? checkoutProvider.orderSuccessContent
                      : "Thank you for submitting your order.\nWe will validate with the supplier\nand give you the order delivery\nconfirmation.";
                  
                  // Decode HTML entities (KEEP TAGS for HTML rendering)
                  final message = CommonMethods.decodeHtmlEntities(rawMessage, stripTags: false);

                  return Html(
                    data: message,
                    style: {
                      "body": Style(
                        fontSize: FontSize(16.sp),
                        color: const Color(0xFF1D2671), // Dark Blue text
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                    },
                  );
                },
              ),
              SizedBox(height: 40.h),

              // Order ID
              Text(
                "Order ID : #$orderId",
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32) // Green color
                    ),
              ),

              SizedBox(height: 50.h),

              // Send Order Receipt Email Button (Orange)
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _showSendReceiptDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryButtonColor, // Dynamic Primary
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r)),
                    elevation: 2,
                  ),
                  child: Text("Send Order Receipt Email",
                      style: TextStyle(fontSize: isTabletLandscape ? 16.sp : 14.sp)),
                ),
              ),
              SizedBox(height: 15.h),

              // Back to Home Button (Dark Blue)
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<DashboardProvider>().setIndex(0); // Home Tab
                    context.go(AppRoutes.dashboard);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryButtonColor, // Dynamic Secondary
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r)),
                    elevation: 2,
                  ),
                  child: Text("Back to Home", style: TextStyle(fontSize: 14.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

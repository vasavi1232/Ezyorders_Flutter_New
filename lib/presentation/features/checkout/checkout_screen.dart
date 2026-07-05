import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/custom_loader_widget.dart';

import '../../../core/constants/storage_keys.dart';
import '../../providers/checkout_provider.dart';
import 'widgets/step_cart_widget.dart';
import 'widgets/step_address_widget.dart';
import 'widgets/step_payment_widget.dart';
import 'widgets/step_preview_widget.dart';
import 'widgets/icon_stepper_widget.dart';
import '../../../../core/constants/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../../../core/utils/common_methods.dart';

class CheckoutScreen extends StatefulWidget {
  final int initialStep;
  const CheckoutScreen({super.key, this.initialStep = 0});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.accessToken) ?? "";
    final userId = prefs.getString(StorageKeys.userId) ?? "";

    if (mounted) {
      context
          .read<CheckoutProvider>()
          .initCheckout(userId, token, initialStep: widget.initialStep);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckoutProvider>();

    // Sync PageController with Provider Step
    if (_pageController.hasClients &&
        _pageController.page?.round() != provider.currentStep) {
      _pageController.jumpToPage(provider.currentStep);
    }

    String title = "My Cart";
    if (provider.currentStep == 1) title = "Address Details";
    if (provider.currentStep == 2) title = "Select Payment Method";
    if (provider.currentStep == 3) title = "Review Details";

    return PopScope(
      canPop: provider.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (provider.currentStep > 0) {
          provider.previousStep();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: AppTheme.backIconSize(context)),
            onPressed: () {
              if (provider.currentStep > 0) {
                provider.previousStep();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                IconStepperWidget(
                  currentStep: provider.currentStep,
                  totalSteps: provider.totalSteps,
                  onStepTapped: (step) {
                    // provider.setStep(step); // Strict flow - no jumping
                  },
                ),
                Builder(builder: (context) {
                  final profileResult = context.read<DashboardProvider>().profileResponse?.results?.firstOrNull;
                  final subtotalVal = double.tryParse(provider.subTotal) ?? 0.0;
                  if (provider.isCartEmpty) return const SizedBox.shrink();
                  String? warningText;

                  final minAmt = double.tryParse(profileResult?.minimumOrderAmount ?? "0") ?? 0.0;
                  final maxAmt = double.tryParse(profileResult?.maxOrderAmount ?? "0") ?? 0.0;

                  // Show Min warning if subtotal < min (even if restrict is No)
                  if (minAmt > 0 && subtotalVal < minAmt) {
                    warningText = CommonMethods.decodeHtmlEntities(profileResult?.minOrderNotificationText, stripTags: true);
                  } 
                  // Show Max warning if subtotal > max (even if restrict is No)
                  else if (profileResult?.maxOrderUnlimited == "No" && subtotalVal > maxAmt) {
                    warningText = CommonMethods.decodeHtmlEntities(profileResult?.maxOrderNotificationText, stripTags: true);
                  }

                  if (warningText == null || warningText.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Text(
                      warningText,
                      style: TextStyle(
                        color: AppTheme.redColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: NeverScrollableScrollPhysics(), // Disable swipe
                    children: [
                      StepCartWidget(),
                      StepAddressWidget(),
                      StepPaymentWidget(),
                      if (provider.isPreviewEnabled) StepPreviewWidget(),
                    ],
                  ),
                ),
              ],
            ),
            if (provider.isLoading)
              Container(
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
              ),

          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/scan_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../core/constants/app_theme.dart';
import 'widgets/scanner_overlay_widget.dart';
import '../../widgets/custom_loader_widget.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  bool _isProcessing = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoDismissTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't start if we are processing a result
        if (!_isProcessing) {
          controller.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Stop the scanner when the app is paused.
        controller.stop();
        break;
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });
    // Stop scanning while processing
    await controller.stop();

    if (!mounted) return;

    final scanProvider = context.read<ScanProvider>();
    final success = await scanProvider.scanProduct(code);

    if (!mounted) return;

    if (success) {
      // Sync cart count
      if (scanProvider.cartQuantity != null) {
        context
            .read<DashboardProvider>()
            .setCartCount(scanProvider.cartQuantity!);
      }
      _showResultDialog(
        title: "Scan Product",
        message: "Scanned Product has been added to Cart.",
        isSuccess: true,
      );
    } else {
      final error = scanProvider.errorMessage ?? "Product not found.";
      _showResultDialog(
        title: "Scan Product",
        message: error,
        isSuccess: false,
      );
    }
  }

  void _showResultDialog(
      {required String title,
      required String message,
      required bool isSuccess}) {
    // Auto dismiss logic
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(Duration(seconds: isSuccess ? 3 : 15), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        _resetScanner();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(0),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 10)),
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
                color: isSuccess ? AppTheme.primaryButtonColor : AppTheme.redColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _autoDismissTimer?.cancel();
                        Navigator.pop(ctx);
                        _resetScanner();
                      },
                      child:
                          Icon(Icons.close, color: Colors.white, size: 24.sp),
                    )
                  ],
                ),
              ),

              // Body
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Text(
                      "Do you want to scan another product?",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100.w,
                          child: ElevatedButton(
                            onPressed: () {
                              _autoDismissTimer?.cancel();
                              Navigator.pop(ctx);
                              _resetScanner();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryButtonColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r)),
                            ),
                            child: Text(
                              "Yes",
                              style: TextStyle(
                                  fontSize: 14.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(width: 25.w),
                        SizedBox(
                          width: 100.w,
                          child: ElevatedButton(
                            onPressed: () {
                              _autoDismissTimer?.cancel();
                              Navigator.pop(ctx);
                              Navigator.pop(context); // Go back to dashboard
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryButtonColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r)),
                            ),
                            child: Text(
                              "No",
                              style: TextStyle(
                                  fontSize: 14.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
    });
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                  color: AppTheme.appbarColor,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ]),
              child: Row(
                children: [
                  SizedBox(width: 10.w),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back,
                        color: Colors.white, size: AppTheme.backIconSize(context)),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: 38.w), // Balance the icon width
                        child: Text(
                          "Scan Product",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Scanner Body
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: _onDetect,
                      ),
                      // Custom Overlay (Green Corners + Red Laser)
                      const ScannerOverlayWidget(),
                      // Loading Overlay
                      Consumer<ScanProvider>(
                        builder: (context, provider, _) {
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

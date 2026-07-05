import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/assets.dart';
import '../../providers/splash_provider.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/error_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initialization after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashProvider>().init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or Theme color
      body: Consumer<SplashProvider>(
        builder: (context, provider, child) {
          if (provider.errorMsg != null) {
            return ErrorView(
              errorMessage: provider.errorMsg,
              onRetry: () => provider.init(context),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Image.asset(
                    AppAssets.appLogo,
                    height: 200.h,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, _, __) => const Icon(Icons.error),
                  ),
                ),
                SizedBox(height: 20.h),
                CustomLoaderWidget(size: 50.w),
              ],
            ),
          );
        },
      ),
    );
  }
}

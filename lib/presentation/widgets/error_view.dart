import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/assets.dart';
import '../../../config/routes/app_routes.dart';

class ErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isFullScreen;

  const ErrorView({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Company Logo
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 50.w),
          child: Image.asset(
            AppAssets.appLogo,
            height: 120.h,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(height: 30.h),
        
        // Professional Error Message
        Text(
          "Something went wrong",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        
        if (errorMessage != null) ...[
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
        
        SizedBox(height: 40.h),
        
        // Retry/Go to Company Selection Button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: SizedBox(
            width: double.infinity,
            height: 45.h,
            child: ElevatedButton(
              onPressed: onRetry ?? () {
                // Default action: Go back to companies selection
                context.go(AppRoutes.companies);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
                elevation: 2,
              ),
              child: Text(
                "Please login again",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(height: 20.h),
        
        // Optional secondary button to just retry current page
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(
              "Try Again",
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            child: content,
          ),
        ),
      );
    } else {
      return Center(
        child: SingleChildScrollView(
          child: content,
        ),
      );
    }
  }
}

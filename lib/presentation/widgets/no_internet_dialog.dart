import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/theme/app_theme.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/connectivity_service.dart';

class NoInternetDialog extends StatelessWidget {
  const NoInternetDialog({super.key});

  static void show(BuildContext context) {
    final connectivityService = getIt<ConnectivityService>();
    if (connectivityService.isDialogShowing) return;

    connectivityService.setDialogShowing(true);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NoInternetDialog(),
    ).then((_) {
      connectivityService.setDialogShowing(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      child: Container(
        width: 300.w,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
              color: AppTheme.redColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "No Internet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Body Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: Text(
                "No Internet Connection, Please try again",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Actions (Ok Button)
            Padding(
              padding: EdgeInsets.only(bottom: 25.h),
              child: SizedBox(
                width: 80.w,
                height: 35.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryButtonColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Ok",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';

class SendOrderReceiptEmailDialog extends StatefulWidget {
  final Function(String) onSend;

  const SendOrderReceiptEmailDialog({
    super.key,
    required this.onSend,
  });

  @override
  State<SendOrderReceiptEmailDialog> createState() =>
      _SendOrderReceiptEmailDialogState();
}

class _SendOrderReceiptEmailDialogState
    extends State<SendOrderReceiptEmailDialog> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      backgroundColor: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: AppTheme.primaryButtonColor,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Send Order Receipt Email",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                RichText(
                  text: TextSpan(
                    text: 'Order Receipt Email(s)',
                    style: TextStyle(
                      color:
                          const Color(0xFF1D2671), // Dark blue from screenshot
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                            color: const Color(0xFF1D2671), fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // Text Field
                TextField(
                  controller: _emailController,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Enter Your Order Receipt Email(s)",
                    hintStyle: TextStyle(color: AppTheme.hintColor,
                      fontSize: 14.sp,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.r),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.r),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // Note
                Text(
                  "Note : Please add Email(s) in comma separated",
                  style: TextStyle(
                    color:
                        const Color(0xFFE91E63), // Pinkish/Red from screenshot
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 24.h),

                // Ok Button
                Center(
                  child: SizedBox(
                    width: 120.w,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_emailController.text.trim().isNotEmpty) {
                          widget.onSend(_emailController.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      child: Text(
                        "Ok",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/forgot_password_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/assets.dart';
import '../../../config/routes/app_routes.dart';
import '../../widgets/custom_loader_widget.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // @color/blue
      body: SafeArea(
        child: Column(
          children: [
            // Outer Layout
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: AppTheme.primaryColor,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: AppTheme.white,
                            child: Column(
                              children: [
                                // Header Card
                                Card(
                                  margin: EdgeInsets.all(0),
                                  elevation: 2,
                                  color: AppTheme.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)),
                                  child: Container(
                                    height: 55,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (context.mounted) {
                                              context.go(AppRoutes.login);
                                            }
                                          },
                                          child: Icon(Icons.arrow_back,
                                              color: AppTheme.blackColor,
                                              size: AppTheme.backIconSize(context)),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "Forgot Password",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppTheme.textColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 45), // Balance spacing
                                      ],
                                    ),
                                  ),
                                ),

                                // Content
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.all(20),
                                    child: Consumer<ForgotPasswordProvider>(
                                      builder: (context, provider, child) {
                                        return Column(
                                          children: [
                                            // Logo
                                            SizedBox(height: 20),
                                            Image.asset(
                                              AppAssets.forgotIcon,
                                              height: 200,
                                              width: 200,
                                            ),
                                            SizedBox(height: 30),

                                            // Form Container
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Label
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(left: 3),
                                                  child: Text(
                                                    "Username *",
                                                    style: TextStyle(
                                                        color: AppTheme
                                                            .primaryColor,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                SizedBox(height: 5),

                                                // Input Field
                                                TextField(
                                                  controller:
                                                      provider.userIdController,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Enter your Email ID/Mobile Number",
                                                    hintStyle: TextStyle(
                                                        color:
                                                            AppTheme.hintColor,
                                                        fontSize: 14),
                                                    filled: true,
                                                    fillColor: AppTheme.white,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 12),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppTheme
                                                                  .inputRadius
                                                                  .r),
                                                      borderSide: BorderSide(
                                                          color: AppTheme
                                                              .borderColor,
                                                          width: 1),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppTheme
                                                                  .inputRadius
                                                                  .r),
                                                      borderSide: BorderSide(
                                                          color: AppTheme
                                                              .borderColor,
                                                          width: 1),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppTheme
                                                                  .inputRadius
                                                                  .r),
                                                      borderSide: BorderSide(
                                                          color: AppTheme
                                                              .borderColor,
                                                          width: 2),
                                                    ),
                                                  ),
                                                  style: TextStyle(
                                                    color: AppTheme.textColor,
                                                    fontSize: 14,
                                                  ),
                                                ),

                                                SizedBox(height: 50),

                                                // Submit Button
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 45,
                                                  child: ElevatedButton(
                                                    onPressed: provider
                                                            .isLoading
                                                        ? null
                                                        : () => provider
                                                            .submit(context),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppTheme.tealColor,
                                                      minimumSize: Size(
                                                          double.infinity,
                                                          45.h),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .circular(AppTheme
                                                                .authButtonRadius
                                                                .r),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Submit",
                                                      style: TextStyle(
                                                          color: AppTheme.white,
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<ForgotPasswordProvider>(
                    builder: (context, provider, child) {
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
                                  // Assuming CustomLoaderWidget is defined elsewhere or will be added
                                  // CustomLoaderWidget(size: 100.w),
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
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

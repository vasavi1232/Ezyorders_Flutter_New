import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/assets.dart';
import '../../../core/constants/url_api_key.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes/app_routes.dart';
import '../../widgets/custom_loader_widget.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../core/utils/common_methods.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load Company Data (Name, Logo, Configs)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadCompanyData();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, provider, child) {
            String imageUrl = provider.companyImage;

            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = UrlApiKey.companyMainUrl + imageUrl;
            }

            return Stack(
              children: [
                Column(
                  children: [
// =====================================================
// SCROLLABLE LOGIN CONTENT
// =====================================================
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: AppTheme.white,
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 20,
                            bottom: 20,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),

// =================================================
// COMPANY NAME
// =================================================
                              Text(
                                provider.companyName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.lightBlue,
                                  fontSize: isTablet ? 16.sp : 14.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 10),

// =================================================
// COMPANY LOGO
// =================================================
                              if (imageUrl.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  height: 120.h,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      const SizedBox(),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                    AppAssets.logo,
                                    height: 120.h,
                                  ),
                                )
                              else
                                Image.asset(
                                  AppAssets.logo,
                                  height: 120.h,
                                ),

                              const SizedBox(height: 20),

// =================================================
// USERNAME LABEL
// =================================================
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Text(
                                    "Username *",
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: isTablet ? 16.sp : 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 5),

// =================================================
// USERNAME INPUT
// =================================================
                              TextField(
                                controller: _emailController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: provider.userNameHint,
                                  hintStyle: TextStyle(
                                    color: AppTheme.hintColor,
                                    fontSize: isTablet ? 16.sp : 14.sp,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.white,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: isTablet ? 18.h : 12.h,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: isTablet ? 16.sp : 14.sp,
                                  color: AppTheme.textColor,
                                ),
                              ),

                              const SizedBox(height: 20),

// =================================================
// PASSWORD LABEL
// =================================================
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Text(
                                    "Password *",
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: isTablet ? 16.sp : 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 5),

// =================================================
// PASSWORD INPUT
// =================================================
                              TextField(
                                controller: _passwordController,
                                obscureText: !provider.isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  hintText: "Enter Your Password",
                                  hintStyle: TextStyle(
                                    color: AppTheme.hintColor,
                                    fontSize: isTablet ? 16.sp : 14.sp,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.white,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: isTablet ? 18.h : 12.h,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      provider.isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppTheme.hintColor,
                                      size: isTablet ? 24.sp : 20.sp,
                                    ),
                                    onPressed:
                                        provider.togglePasswordVisibility,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: isTablet ? 16.sp : 14.sp,
                                  color: AppTheme.textColor,
                                ),
                              ),

                              const SizedBox(height: 20),

// =================================================
// FORGOT PASSWORD
// =================================================
                              GestureDetector(
                                onTap: () {
                                  if (context.mounted) {
                                    context.push(
                                      AppRoutes.forgotPassword,
                                    );
                                  }
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: AppTheme.tealColor,
                                      fontSize: isTablet ? 16.sp : 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 16.h),

// =================================================
// LOGIN BUTTON
// =================================================
                              SizedBox(
                                width: double.infinity,
                                height: isTablet ? 60.h : 45.h,
                                child: ElevatedButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : () async {
                                          final success = await provider.login(
                                            _emailController.text.trim(),
                                            _passwordController.text.trim(),
                                          );

                                          if (success && context.mounted) {
                                            context.go(
                                              AppRoutes.dashboard,
                                            );
                                          } else if (provider.errorMessage !=
                                              null) {
                                            if (provider.errorStatus == 500 &&
                                                context.mounted) {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10.r,
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.all(20.w),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Html(
                                                        data: CommonMethods
                                                            .decodeHtmlEntities(
                                                          provider
                                                              .errorMessage!,
                                                          stripTags: false,
                                                        ),
                                                      ),
                                                      SizedBox(height: 20.h),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                            context,
                                                          ),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                AppTheme
                                                                    .primaryButtonColor,
                                                          ),
                                                          child: Text(
                                                            "OK",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: isTablet ? 18.sp : 14.sp,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            } else if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .clearSnackBars();

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    provider.errorMessage!,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppTheme.primaryButtonColor,
                                    minimumSize: Size(
                                      double.infinity,
                                      isTablet ? 60.h : 45.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.authButtonRadius,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontSize: isTablet ? 16.sp : 14.sp,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

// =================================================
// SIGN UP BUTTON
// =================================================
                              if (provider.isSignupRequired)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 20,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: isTablet ? 60.h : 45.h,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (context.mounted) {
                                          context.push(
                                            AppRoutes.signup,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.signupButtonColor,
                                        minimumSize: Size(
                                          double.infinity,
                                          isTablet ? 60.h : 45.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.authButtonRadius,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Don’t have an account? Sign Up",
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: isTablet ? 16.sp : 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

// Additional bottom space for scrolling
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

// =========================================================
// FIXED BOTTOM SECTION
// ACCESS OTHER STORES
// =========================================================
                    Container(
                      width: double.infinity,
                      color: AppTheme.white,
                      padding: EdgeInsets.only(
                        left: isTablet ? 120.w : 70.w,
                        right: isTablet ? 120.w : 70.w,
                        top: 10.h,
                        bottom: 30.h,
                      ),
                      child: SafeArea(
                        top: false,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.r),
                          onTap: () async {
                            await provider.clearSession();

                            if (context.mounted) {
                              context.go(
                                AppRoutes.companies,
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: isTablet ? 65.h : 50.h,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryButtonColor,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.list,
                                  size: isTablet ? 32.sp : 24.sp,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "Access Other Stores",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 20.sp : 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

// =============================================================
// LOADING OVERLAY
// =============================================================
                if (provider.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: SizedBox(
                          width: 100.w,
                          height: 100.w,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
// Rotating Loader
                              CustomLoaderWidget(
                                size: 100.w,
                              ),

// Loading Text
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

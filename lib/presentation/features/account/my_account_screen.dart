import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../config/routes/app_routes.dart';
import '../../../core/constants/url_api_key.dart';
import '../dashboard/widgets/logout_dialog.dart';
import '../dashboard/widgets/close_account_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          final user = provider.profileResponse?.results?.firstOrNull;
          final userName =
              "${user?.firstName ?? ''} ${user?.lastName ?? ''}".trim();
          final userEmail = user?.email ?? '';
          final userImage = user?.image ?? '';

          return Column(
            children: [
              // Custom Header
              Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  // Invisible child to define the Stack's hit-test area
                  SizedBox(height: 210.h, width: double.infinity),
                  Container(
                    height: 160.h,
                    width: double.infinity,
                    color: AppTheme.tealColor, // Orange
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    child: Stack(
                      children: [
                        // Back Button
                        Positioned(
                          left: 10.w,
                          top: 10.h,
                          child: InkWell(
                            onTap: () {
                              context.read<DashboardProvider>().setIndex(0);
                              context.go(AppRoutes.dashboard);
                            },
                            child: Icon(Icons.arrow_back,
                                color: Colors.white, size: AppTheme.backIconSize(context)),
                          ),
                        ),
                        // Title
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Text(
                              "Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Image (Centered and Overlapping)
                  Positioned(
                    bottom:
                        0, // Changed from -50.h because the Stack is now taller
                    child: Stack(
                      children: [
                        InkWell(
                          onTap: () {
                            context.push(AppRoutes.myProfile);
                          },
                          child: Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              //border: Border.all(color: Colors.white, width: 3),
                              color: Colors.grey.shade200,
                              image: (userImage.isNotEmpty &&
                                      !userImage.contains("default"))
                                  ? DecorationImage(
                                      image: NetworkImage(userImage
                                              .startsWith("http")
                                          ? userImage
                                          : "${UrlApiKey.mainUrl}$userImage"),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: (userImage.isEmpty ||
                                    userImage.contains("default"))
                                ? Icon(Icons.person,
                                    size: 60.w, color: Colors.grey)
                                : null,
                          ),
                        ),
                        // Edit Icon
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              context.push(AppRoutes.myProfile);
                            },
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400, width: 1),
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 18.sp,
                                color: Colors.black, // Dark Teal/Cyan like screenshot
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(
                  height: 10.h), // Reduced height because Stack is now taller

              // User Info (Plain Text)
              Text(
                userName.isEmpty ? "Guest User" : userName,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 20.h),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Menu Items
                      if (provider.profileResponse?.results?.firstOrNull
                              ?.allowCustomersToAddWishlist !=
                          "No")
                        _buildMenuItem(
                            context,
                            'assets/images/my_fav.png',
                            provider.profileResponse?.results?.firstOrNull
                                    ?.wishlistPageHeading ??
                                "My Favourites", () {
                          context.push(AppRoutes.myWishlist);
                        }),
                      _buildMenuItem(
                          context, 'assets/images/my_orders.png', "My Orders",
                          () {
                        context.push(AppRoutes.myOrders);
                      }),

                      _buildMenuItem(
                          context,
                          'assets/images/changepasswordicon.png',
                          "Change Password", () {
                        context.push(AppRoutes.changePassword);
                      }),
                      _buildMenuItem(context, 'assets/images/addressesicon.png',
                          "Address List", () {
                        // TODO: Navigate to Address Book
                        context.push(AppRoutes.myAddresses);
                      }),
                      _buildMenuItem(
                          context, 'assets/images/my_logout.png', "Logout", () {
                        _showLogoutDialog(context, provider);
                      }),

                      SizedBox(height: 20.h),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: InkWell(
                          onTap: () async {
                            final dashboardProvider = context.read<DashboardProvider>();
                            final response = await dashboardProvider.getCloseAccountMessage();
                            if (response['status'] == 200 && response['results'] != null && response['results'].isNotEmpty) {
                              final htmlMessage = response['results'][0]['delete_customer_account_message'];
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => CloseAccountDialog(htmlMessage: htmlMessage ?? ""),
                                );
                              }
                            } else {
                              Fluttertoast.showToast(msg: "Failed to get message");
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white, size: 22.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  "Close Account",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String assetPath, String title,
      VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
                color: AppTheme.white, // Light Teal
                borderRadius: BorderRadius.circular(8.r)),
            child: Image.asset(
              assetPath,
              height: 24.sp,
              width: 26.sp,
              fit: BoxFit.contain,
              color: AppTheme.primaryColor,
            ),
          ),
          title: Text(title,
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor)),
          /*trailing: Icon(Icons.arrow_forward_ios,
              size: 16.sp, color: AppTheme.primaryColor),*/
          onTap: onTap,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.black38,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, DashboardProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => LogoutDialog(
        onYes: () {
          provider.logout();
          context.go(AppRoutes.login);
        },
      ),
    );
  }
}

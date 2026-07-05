import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/cart/widgets/empty_cart_dialog.dart';

import '../../config/routes/app_routes.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/common_methods.dart';
import '../providers/dashboard_provider.dart';
import '../providers/product_list_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isPortalBlocked) {
          return const SizedBox.shrink();
        }
        
        final bool isTablet = MediaQuery.of(context).size.width > 600;
        final double labelSize = isTablet ? 15.sp : 12.sp;
        final double iconSize = isTablet ? 35.sp : 30.sp;
        final double profileIconSize = isTablet ? 30.sp : 24.sp;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = constraints.maxWidth / 4;

              return Stack(
                children: [
                  BottomNavigationBar(
                    backgroundColor: Colors.white,
                    onTap: (index) {
                      if (index == 2) {
                        // Cart Tab handling
                        if (dashboardProvider.cartQuantity == "0") {
                          // If cart is empty, show the dialog
                          showDialog(
                            context: context,
                            builder: (context) => const EmptyCartDialog(),
                          );
                        } else {
                          // Otherwise, open Checkout Screen (Step 0)
                          context.push(AppRoutes.checkout,
                              extra: {'initialStep': 0}).then((_) {
                            // Refresh cart count on return
                            dashboardProvider
                                .setCartCount(CommonMethods.cartCount);
                            if (dashboardProvider.currentIndex == 1) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (context.mounted) {
                                  final profile = dashboardProvider.profileResponse?.results?.isEmpty == true 
                                      ? null 
                                      : dashboardProvider.profileResponse?.results?[0];
                                  context.read<ProductListProvider>().init(
                                    isTablet: AppTheme.isTablet(context),
                                    profile: profile,
                                  );
                                }
                              });
                            }
                          });
                        }
                        return;
                      }

                        if (index == 0) {
                          // Reset filters when going Home
                          context.read<ProductListProvider>().clearFilters();
                          // Home Tab handling: Refresh data
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              context.read<DashboardProvider>().init();
                            }
                          });
                        }

                      if (index == 1) {
                        context.read<ProductListProvider>().clearFilters();
                        CommonMethods.productsBack = "dashboard";
                        // Always re-fetch products when "Order Now" is visited
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            final profile = dashboardProvider.profileResponse?.results?.isEmpty == true 
                                ? null 
                                : dashboardProvider.profileResponse?.results?[0];
                            context.read<ProductListProvider>().init(
                              isTablet: AppTheme.isTablet(context),
                              profile: profile,
                            );
                          }
                        });
                      }

                      if (index == 3) {
                        // Reset filters when going to My Account
                        context.read<ProductListProvider>().clearFilters();
                      }

                      // For other tabs, we might need to navigate to Dashboard first
                      // if we are not already there (e.g., from ProductDetailsScreen).
                      // Setting index before nav ensures correct tab is shown.
                      dashboardProvider.setIndex(index);

                      // Check if we need to navigate.
                      // Using go() ensures we clear stack or jump to the route.
                      // Since Dashboard is likely stateless in router or shell, this works.
                      // We can check current location but go() is safe.
                      while (context.canPop()) {
                        context.pop();
                      }
                      GoRouter.of(context).go(AppRoutes.dashboard);
                    },
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: AppTheme.primaryColor,
                    unselectedItemColor: AppTheme.primaryColor,
                    currentIndex: dashboardProvider.currentIndex,
                    selectedLabelStyle: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w700,
                    ),
                    items: [
                      BottomNavigationBarItem(
                        icon: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/images/homeicon_new.png",
                              width: iconSize,
                              height: iconSize,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(height: 2.h),
                          ],
                        ),
                        label: "Home",
                      ),
                      BottomNavigationBarItem(
                        icon: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/images/order_now.png",
                              width: iconSize,
                              height: iconSize,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(height: 2.h),
                          ],
                        ),
                        label: "Order Now",
                      ),
                      BottomNavigationBarItem(
                        icon: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Badge(
                              label: Text(
                                dashboardProvider.cartQuantity,
                                style: TextStyle(
                                  fontSize: isTablet ? 14.sp : 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.red,
                              isLabelVisible:
                                  dashboardProvider.cartQuantity != "0",
                              child: Image.asset(
                                "assets/images/carticon_new.png",
                                width: iconSize,
                                height: iconSize,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            SizedBox(height: 2.h),
                          ],
                        ),
                        label: "My Cart",
                      ),
                      BottomNavigationBarItem(
                        icon: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/images/profile_tab.png",
                              width: profileIconSize,
                              height: profileIconSize,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(height: 2.h),
                          ],
                        ),
                        label: "My Account",
                      ),
                    ],
                  ),

                  // Vertical Dividers
                  Positioned(
                    left: itemWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Positioned(
                    left: itemWidth * 2,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Positioned(
                    left: itemWidth * 3,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

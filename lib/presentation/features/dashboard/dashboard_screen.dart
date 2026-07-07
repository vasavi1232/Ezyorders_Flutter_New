import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../config/routes/app_routes.dart';
import '../../../data/models/home_models.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/assets.dart';
import '../../../core/constants/url_api_key.dart';
import '../../../core/utils/common_methods.dart';
import '../../widgets/error_view.dart';
import '../../../core/network/image_cache_manager.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_list_provider.dart';
import '../../widgets/gst_message_widget.dart';
import 'widgets/flash_deals_section.dart';
import 'widgets/home_blocks_section.dart';
import 'widgets/logout_dialog.dart';
import 'widgets/close_account_dialog.dart';
import 'widgets/popular_ads_section.dart';
import 'widgets/popular_categories_section.dart';
import 'widgets/promotions_section.dart';
import 'widgets/section_header_widget.dart';
import 'widgets/standard_product_sections.dart';
import 'widgets/suppliers_section.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../products/widgets/product_details_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _bannerController;
  late PageController _footerPageController;
  Timer? _bannerTimer;
  Timer? _footerBannerTimer;
  int _currentBannerIndex = 0;
  int _currentFooterIndex = 0;
  late AnimationController _marqueeController;
  late Animation<double> _marqueeAnimation;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22), // Speed (increase = slower)
    )..repeat();
    _marqueeAnimation = Tween<double>(
      begin: 1.0,
      end: -1.0,
    ).animate(CurvedAnimation(
      parent: _marqueeController,
      curve: Curves.linear,
    ));
    _bannerController = PageController();
    _footerPageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().init();
      _startBannerTimer();
      _startFooterBannerTimer();
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final provider = context.read<DashboardProvider>();
      if (provider.bannersResponse?.results != null &&
          provider.bannersResponse!.results!.isNotEmpty) {
        int nextIndex = _currentBannerIndex + 1;
        if (nextIndex >= provider.bannersResponse!.results!.length) {
          nextIndex = 0;
        }
        if (_bannerController.hasClients) {
          _bannerController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _startFooterBannerTimer() {
    _footerBannerTimer?.cancel();
    _footerBannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final provider = context.read<DashboardProvider>();
      if (provider.footerBannersResponse?.results != null &&
          provider.footerBannersResponse!.results!.isNotEmpty) {
        int nextIndex = _currentFooterIndex + 1;
        if (nextIndex >= provider.footerBannersResponse!.results!.length) {
          nextIndex = 0;
        }
        if (_footerPageController.hasClients) {
          _footerPageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _footerBannerTimer?.cancel();
    _bannerController.dispose();
    _footerPageController.dispose();
    _marqueeController.dispose();

    super.dispose();
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      debugPrint("Image URL Path is Null or Empty");
      return "";
    }
    debugPrint("Processing Image Path: $path");
    if (path.startsWith("http") || path.startsWith("https")) return path;
    return "${UrlApiKey.mainUrl}$path";
  }

  Widget _buildNetworkImage(String? path, {BoxFit fit = BoxFit.cover}) {
    final url = _getImageUrl(path);
    if (url.isEmpty) {
      return Image.asset(
        AppAssets.placeholder,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: ImageCacheManager(),
      // Use custom cache manager with SSL bypass
      fit: fit,
      errorWidget: (context, url, error) => Image.asset(
        AppAssets.placeholder,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      ),
      placeholder: (context, url) => Container(color: Colors.grey[200]),
    );
  }

  Future<void> _handleBannerTap(BannerItem? banner) async {
    if (banner == null) return;

    if (banner.linkImageTo == "No Link") {
      return;
    }

    if (banner.linkImageTo == "Link To External Site") {
      if (banner.externalLink != null && banner.externalLink!.isNotEmpty) {
        final Uri uri = Uri.parse(banner.externalLink!);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          debugPrint("Could not launch ${banner.externalLink}");
        }
      }
      return;
    }

    if (banner.linkImageTo == "Link To Product") {
      if (banner.productId != null && banner.productId != "0") {
        final productListProvider = context.read<ProductListProvider>();
        await productListProvider.fetchProductDetails(banner.productId!);
        if (mounted && productListProvider.productDetailItem != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ProductDetailsBottomSheet(
                product: productListProvider.productDetailItem!),
          );
        }
      }
      return;
    }

    // Default Fallback
    final productProvider = context.read<ProductListProvider>();
    productProvider.clearFilters();
    productProvider.setBannerNavigation(banner: banner);

    final dashboardProvider = context.read<DashboardProvider>();
    final profile = dashboardProvider.profileResponse?.results?.firstOrNull;
    productProvider.init(
      isTablet: AppTheme.isTablet(context),
      profile: profile,
    );

    context.read<DashboardProvider>().setIndex(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 4, // 👈 controls shadow intensity
        shadowColor: Colors.black.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            size: 30.sp,
            weight: 300,
            color: Colors.white,
          ), // Thinner menu icon
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Selector<DashboardProvider, String?>(
          selector: (context, provider) => provider.companyImage,
          builder: (context, companyImage, child) {
            if (companyImage != null && companyImage.isNotEmpty) {
              return CachedNetworkImage(
                imageUrl: _getImageUrl(companyImage),
                height: 36.h,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox.shrink(),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              final unreadCount = provider.unreadNotificationCount;
              final hasUnread = unreadCount > 0;

              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      AppAssets.bellIcon,
                      width: 30.sp,
                      height: 30.sp,
                      color: Colors.white,
                    ),
                    if (hasUnread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.w,
                            minHeight: 16.w,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  context.push(AppRoutes.notifications);
                },
              );
            },
          ),

        ],
      ),
      drawer: _buildDrawer(),
      body: VisibilityDetector(
        key: const Key('dashboard-visibility-key'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 1.0) {
            // When the screen becomes fully visible (e.g., returning from another screen), refresh data
            if (mounted) {
              context.read<DashboardProvider>().init();
            }
          }
        },
        child: Stack(
          children: [
            Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              if (provider.isPortalBlocked) {
                return Container(
                  color: Colors.white,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        "Sorry for the inconvenience. ${provider.companyName ?? 'The Store'} is closed today",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.blackColor,
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (provider.errorMsg != null && !provider.isLoading) {
                return ErrorView(
                  errorMessage: provider.errorMsg,
                  onRetry: () => provider.refreshDashboard(),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await provider.refreshDashboard(isSilent: true);
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      _buildMarquee(provider),
                      SizedBox(height: 10.h),
                      _buildBanners(provider),
                      GstMessageWidget(),
                      _buildTopSuppliers(provider),
                      //SizedBox(height: 15.h),
                      const HomeBlocksSection(),
                      _buildProductSections(provider),
                      _buildBottomSuppliers(provider),
                      SizedBox(height: 10.h), // Bottom padding
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ));
  }

  Widget _buildDrawer() {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isTablet = mediaQuery.size.shortestSide >= 600;
    
    // Increase drawer width in landscape mode for tablets
    double drawerWidth = 304.0; // Default Flutter drawer width
    if (isLandscape && isTablet) {
      drawerWidth = mediaQuery.size.width * 0.4; // 40% of screen width
    }

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Consumer<DashboardProvider>(
            builder: (context, provider, _) {
              final user = provider.profileResponse?.results?.isNotEmpty == true
                  ? provider.profileResponse!.results![0]
                  : null;

              return InkWell(
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  context.push(AppRoutes.myProfile);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                      color: AppTheme.tealColor), // Teal
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30.r,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              user?.image != null && user!.image!.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      _getImageUrl(user.image)) as ImageProvider
                                  : const AssetImage(AppAssets.userIcon),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${user?.firstName ?? ''} ${user?.lastName ?? ''}",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? "user@example.com",
                                maxLines: 2,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13.sp),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Image.asset(AppAssets.menuCloseIcon,
                              width: 20.w, height: 20.w, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Consumer<DashboardProvider>(
                    builder: (context, provider, _) {
                      final allowScan = provider.profileResponse?.results
                              ?.firstOrNull?.allowScanToOrder ==
                          "Yes";
                      if (!allowScan) return const SizedBox.shrink();
                      return _buildDrawerItem(AppAssets.scanIcon, "Scan to Order", () {
                        context.pop();
                        context.push(AppRoutes.scan);
                      });
                    },
                  ),
                  Consumer<DashboardProvider>(
                    builder: (context, provider, _) {
                      final allowWishlist = provider.profileResponse?.results
                              ?.firstOrNull?.allowCustomersToAddWishlist ==
                          "Yes";
                      final wishlistHeading = provider.profileResponse?.results
                              ?.firstOrNull?.wishlistPageHeading ??
                          "My Favourites";
                      if (!allowWishlist) return const SizedBox.shrink();
                      return _buildDrawerItem(
                          AppAssets.favIcon, wishlistHeading, () {
                        context.pop(); // Close drawer
                        context.read<ProductListProvider>().clearFilters();
                        context.push(AppRoutes.myWishlist);
                      });
                    },
                  ),
                  _buildDrawerItem(AppAssets.myOrdersIcon, "My Orders", () {
                    context.pop();
                    context.read<ProductListProvider>().clearFilters();
                    context.push(AppRoutes.myOrders);
                  }),
                  _buildDrawerItem(AppAssets.orderNowIcon, "Order Now", () {
                    context.pop();
                    context.read<ProductListProvider>().clearFilters();
                    CommonMethods.productsBack = "dashboard";
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        final dashboardProvider = context.read<DashboardProvider>();
                        final profile = dashboardProvider.profileResponse?.results?.isEmpty == true 
                            ? null 
                            : dashboardProvider.profileResponse?.results?[0];
                        context.read<ProductListProvider>().init(
                          isTablet: AppTheme.isTablet(context),
                          profile: profile,
                        );
                      }
                    });
                    context.read<DashboardProvider>().setIndex(1);
                  }),
                  _buildDrawerItem(AppAssets.promoIcon, "Promotions", () {
                    context.pop();
                    context.read<ProductListProvider>().clearFilters();
                    context.read<DashboardProvider>().clearPromotions();
                    context.push(AppRoutes.promotions);
                  }),
                  _buildDrawerItem(AppAssets.notifyIcon, "Notifications", () {
                    context.pop();
                    context.read<ProductListProvider>().clearFilters();
                    context.push(AppRoutes.notifications);
                  }),
                  _buildDrawerItem(AppAssets.faqIcon, "FAQ", () {
                    context.pop();
                    context.push(AppRoutes.faq);
                  }),
                  _buildDrawerItem(AppAssets.helpIcon, "Help & Support", () {
                    context.pop();
                    context.push(AppRoutes.helpSupport);
                  }),
                  _buildDrawerItem(AppAssets.feedbackIcon, "Send Feedback", () {
                    context.pop();
                    context.push(AppRoutes.sendFeedback);
                  }),
                  _buildDrawerItem(AppAssets.aboutIcon, "About Us", () {
                    context.pop();
                    context.push(AppRoutes.aboutUs);
                  }),
                ],
              ),
            ),
          ),
          // Footer Logout
          Container(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => LogoutDialog(
                    onYes: () async {
                      await context.read<DashboardProvider>().logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryButtonColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppAssets.logoutMenuIcon,
                        width: 20.w,
                        height: 20.w,
                        color: AppTheme.white),
                    SizedBox(width: 10.w),
                    Text("Logout",
                        style: TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String iconPath, String title, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Image.asset(
            iconPath,
            width: 20,
            height: 20,
            color: AppTheme.primaryColor,
          ),
          title: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          onTap: onTap,
          dense: true,
          horizontalTitleGap: 0,
        ),

        // 👇 Divider Line
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade300,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }

  Widget _buildMarquee(DashboardProvider provider) {
    final profile = provider.profileResponse?.results?.isNotEmpty == true
        ? provider.profileResponse!.results![0]
        : null;

    if (profile == null ||
        profile.showMarqueText != "Yes" ||
        profile.marqueText == null ||
        profile.marqueText!.isEmpty) {
      return const SizedBox.shrink();
    }

    Color textColor = Colors.red;
    if (profile.marqueTextColor != null &&
        profile.marqueTextColor!.isNotEmpty) {
      try {
        String hex = profile.marqueTextColor!.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        textColor = Color(int.parse('0x$hex'));
      } catch (_) {}
    }

    Color bgColor = Colors.white;
    if (profile.marqueTextBackgroundColor != null &&
        profile.marqueTextBackgroundColor!.isNotEmpty) {
      try {
        String hex = profile.marqueTextBackgroundColor!.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        bgColor = Color(int.parse('0x$hex'));
      } catch (_) {}
    }

    FontStyle fontStyle = FontStyle.normal;
    FontWeight fontWeight = FontWeight.normal;

    if (profile.marqueTextFormat == "Italic") {
      fontStyle = FontStyle.italic;
    } else if (profile.marqueTextFormat == "Bold") {
      fontWeight = FontWeight.bold;
    } else if (profile.marqueTextFormat == "Normal") {
      fontWeight = FontWeight.normal;
    } else {
      fontWeight = FontWeight.bold;
      fontStyle = FontStyle.italic;
    }

    double fontSize =
        (double.tryParse(profile.marqueTextSize ?? '') ?? 18.0).sp;

    return Container(
      height: 40.h,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _marqueeAnimation,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(_marqueeAnimation.value, 0),
            child: child,
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0.h),
          child: Text(
            profile.marqueText!,
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              fontSize: fontSize,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }

  Widget _buildBanners(DashboardProvider provider) {
    if (provider.bannersResponse?.results == null ||
        provider.bannersResponse!.results!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        SizedBox(
          height: 180.h, // Adjusted height to match compact look
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: provider.bannersResponse!.results!.length,
            itemBuilder: (context, index) {
              final banner = provider.bannersResponse!.results![index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                // Matches Image 2 side margins
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0.r),
                  child: InkWell(
                    onTap: () => _handleBannerTap(banner),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildNetworkImage(banner?.image, fit: BoxFit.fill),
                        // Overlay Card (Bottom Left)
                        Positioned(
                          bottom: 50.h,
                          left: 15.w,
                          child: Container(
                            width: 140.w, // Approximate width from screenshot
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: AppTheme.borderColor,
                                width: 1.5, // Adjust thickness if needed
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (banner?.topCaption != null &&
                                    banner!.topCaption!.isNotEmpty)
                                  Text(
                            CommonMethods.decodeHtmlEntities(banner.topCaption!),
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                  ),
                                Text(
                                  CommonMethods.decodeHtmlEntities(banner?.name ?? ""),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (banner?.bottomCaption != null &&
                                    banner!.bottomCaption!.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2.h),
                                    child: Text(
                                      CommonMethods.decodeHtmlEntities(banner.bottomCaption!),
                                      style: TextStyle(
                                          color: Colors.grey[700], 
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                SizedBox(height: 8.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryButtonColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    "Shop Now",
                                    style: TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        DotsIndicator(
          dotsCount: provider.bannersResponse!.results!.length,
          position: _currentBannerIndex,
          decorator: DotsDecorator(
            size: Size.square(6.0.w),
            // Smaller dots
            activeSize: Size(12.0.w, 6.0.w),
            // Ellipse for active
            activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.0.r)),
            activeColor: AppTheme.darkBlue,
            // Dark blue from Image 2
            color: AppTheme.hintColor.withValues(alpha: 0.3),
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildTopSuppliers(DashboardProvider provider) {
    final profile = provider.profileResponse?.results?.firstOrNull;
    // Gate: supplier_logos must be "Show" AND position must be "Top"
    if (profile?.supplierLogos == "Show" && provider.supplierLogosPosition == "Top") {
      return const SuppliersSection();
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomSuppliers(DashboardProvider provider) {
    final profile = provider.profileResponse?.results?.firstOrNull;
    // Gate: supplier_logos must be "Show" AND position is NOT "Top"
    if (profile?.supplierLogos == "Show" && provider.supplierLogosPosition != "Top") {
      return const SuppliersSection();
    }
    return const SizedBox.shrink();
  }

  Widget _buildProductSections(DashboardProvider provider) {
    final profile = provider.profileResponse?.results?.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Promotions & Popular Categories are always shown (Android always calls these APIs)
        PromotionsSection(),
        if (profile?.popularCategories == "Show") PopularCategoriesSection(),
        if (profile?.bestSellers == "Show") BestSellersSection(),
        if (profile?.flashDeals == "Show") FlashDealsSection(),
        if (profile?.hotSelling == "Show") HotSellingSection(),
        if (profile?.newArrivals == "Show") NewArrivalsSection(),
        if (profile?.productsAdvertisements == "Show") PopularAdsSection(),
        _buildFooterBanners(provider),
        if (profile?.recentlyAdded == "Show") RecentlyAddedSection(),
      ],
    );
  }


  Widget _buildFooterBanners(DashboardProvider provider) {
    final results = provider.footerBannersResponse?.results;
    if (results == null || results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 15.h,
        ),
        SectionHeaderWidget(
          title: "", // No title for footer banners usually, but has arrows
          onPrevTap: _currentFooterIndex > 0
              ? () {
                  int prevIndex = _currentFooterIndex - 1;
                  _footerPageController.animateToPage(
                    prevIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
          onNextTap: _currentFooterIndex < results.length - 1
              ? () {
                  int nextIndex = _currentFooterIndex + 1;
                  _footerPageController.animateToPage(
                    nextIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
        ),
        SizedBox(
          height: 120.h,
          child: PageView.builder(
            controller: _footerPageController,
            itemCount: results.length,
            onPageChanged: (index) {
              setState(() {
                _currentFooterIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = results[index];
              if (banner?.image == null) return const SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: InkWell(
                    onTap: () => _handleBannerTap(banner),
                  child: SizedBox(
                    width: double.infinity, // ✅ full width
                    child: _buildNetworkImage(
                      banner!.image,
                      fit: BoxFit.cover, // better full-width fit
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

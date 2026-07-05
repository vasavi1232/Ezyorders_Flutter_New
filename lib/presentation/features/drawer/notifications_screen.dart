import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/utils/common_methods.dart';

import '../../../../data/models/drawer_models.dart';

import '../../../config/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_routes.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import 'widgets/notification_item_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(page: 1);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData({required int page}) {
    _currentPage = page;
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    provider.fetchNotifications(page);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      if (!provider.isFetchingDrawerData) {
        _loadData(page: _currentPage + 1);
      }
    }
  }

  void _showNotificationDetails(NotificationItem item) {
    if (item.status == "UnRead" && item.notificationId != null) {
      Provider.of<DashboardProvider>(context, listen: false)
          .changeNotificationStatus(item.notificationId!);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String imageUrl = item.image ?? "";
        if (imageUrl.isNotEmpty && !imageUrl.startsWith("http")) {
          imageUrl = "${UrlApiKey.mainUrl}$imageUrl";
        }
        bool hasImage = CommonMethods.hasValidImage(imageUrl);
        // Default to showing image BEFORE text unless specifically set to "After Message"
        bool isBeforeImage = !(item.imagePosition?.toLowerCase().trim().contains("after") ?? false);

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Orange header bar (matches native Android dialog_notifydetails) ──
              Container(
                color: AppTheme.primaryButtonColor,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Notification Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.white, size: 22.sp),
                    ),
                  ],
                ),
              ),

              // ── Content ──
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1) Subject (Title) is ALWAYS first
                    if ((item.title ?? "").isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Text(
                          item.title ?? "",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                    // 2) Layout based on image_position
                    if (isBeforeImage) ...[
                      // CASE: Before Message (Subject -> Image -> Message)
                      if (hasImage)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 160.h,
                            fit: BoxFit.contain,
                            errorWidget: (ctx, url, e) =>
                                Icon(Icons.broken_image, size: 60.sp, color: Colors.grey),
                          ),
                        ),
                      if ((item.description ?? "").isNotEmpty)
                        Text(
                          item.description ?? "",
                          style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                        ),
                    ] else ...[
                      // CASE: After Message (Subject -> Message -> Image)
                      if ((item.description ?? "").isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Text(
                            item.description ?? "",
                            style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                          ),
                        ),
                      if (hasImage)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 160.h,
                          fit: BoxFit.contain,
                          errorWidget: (ctx, url, e) =>
                              Icon(Icons.broken_image, size: 60.sp, color: Colors.grey),
                        ),
                    ],

                    SizedBox(height: 16.h),

                    // OK button centered (matches native Android)
                    Center(
                      child: SizedBox(
                        width: 80.w,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryButtonColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        elevation: 4, // 👈 controls shadow intensity
        shadowColor: Colors.black.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: AppTheme.backIconSize(context)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
      body: Stack(
        children: [
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              if (provider.isFetchingDrawerData &&
                  provider.notificationsResponse == null) {
                return const SizedBox.shrink(); // Overlay handles it
              }

              final notifications = provider.notificationsResponse?.results;

              if (notifications == null || notifications.isEmpty) {
                return Center(
                  child: Text(
                    "No Notifications Available",
                    style: TextStyle(
                        fontSize: 16.sp,
                        color: AppTheme.tealColor,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(10.w),
                itemCount: notifications.length +
                    (provider.isFetchingDrawerData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == notifications.length) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: CustomLoaderWidget(size: 30.w)),
                    );
                  }
                  final item = notifications[index];
                  return NotificationItemWidget(
                    item: item,
                    onTap: () {
                      _showNotificationDetails(item);
                    },
                    onDelete: () {
                      if (item.notificationId != null) {
                        provider.deleteNotification(item.notificationId!);
                      }
                    },
                  );
                },
              );
            },
          ),
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              // Overlay for:
              // 1. Initial Load (fetching && no data)
              // 2. Generic Loading (e.g. Delete action)
              final noData = provider.notificationsResponse?.results == null ||
                  provider.notificationsResponse!.results!.isEmpty;

              if (provider.isLoading ||
                  (provider.isFetchingDrawerData && noData)) {
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
    );
  }
}

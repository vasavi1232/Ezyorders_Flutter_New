import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/gst_message_widget.dart';
import 'widgets/promotion_item_widget.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    // Determine page to fetch (1 if refreshing or initial)
    // Actually DashboardProvider has promotionPage state.
    // We should probably reset to 1 when entering this screen if viewed as a "list"
    // But Dashboard uses the same response.
    // Let's just fetch page 1 to be safe and ensure list is up to date.
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    provider.fetchPromotions(page: 1);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      
      // Avoid multiple triggers if already loading
      if (provider.isPromotionsLoading) return;

      // Check if we have more pages to fetch
      final totalPages = provider.promotionsResponse?.totalPages ?? 1;
      if (provider.promotionPage < totalPages) {
        provider.fetchPromotions(page: provider.promotionPage + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Promotions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: AppTheme.backIconSize(context)),
          onPressed: () => context.pop(),
        ),
        /*actions: [
          // Cart Icon (Placeholder logic for now, matching Android visual)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shopping_cart, size: 24.sp),
                  // Count badge could represent cart count if available
                ],
              ),
            ),
          )
        ],*/
      ),
      body: Stack(
        children: [
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              final promotions = provider.promotionsResponse?.results;

              if (provider.isPromotionsLoading && promotions == null) {
                return const SizedBox.shrink(); // Overlay handles it
              }

              if (promotions == null || promotions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "No Promotions Available",
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Subtract top padding before dividing so 3 cards still fit perfectly
                        final itemHeight = (constraints.maxHeight - 10.h) / 3;
                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 0),
                          itemCount:
                              promotions.length + (provider.isPromotionsLoading ? 1 : 0) + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return GstMessageWidget(
                                padding: EdgeInsets.only(bottom: 10.h),
                              );
                            }

                            final promoIndex = index - 1;

                            if (promoIndex == promotions.length) {
                              if (!provider.isPromotionsLoading) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(child: CustomLoaderWidget(size: 30.w)),
                              );
                            }
                            return PromotionItemWidget(
                              item: promotions[promoIndex],
                              index: promoIndex,
                              itemHeight: itemHeight,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              // Show overlay only if initial load (no data yet)
              // If data exists, we show pagination loader at bottom (handled above)
              // BUT if we want blocking overlay for refresh?
              // Android typically blocks on initial load. Pagination is non-blocking.
              // Logic: if isLoading && promotions == null => Blocking Overlay
              // if isLoading && promotions != null => Pagination Loader (in list)

              if (provider.isPromotionsLoading &&
                  provider.promotionsResponse?.results == null) {
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
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/product_list_provider.dart';
import '../../../../core/utils/common_methods.dart';

import '../../drawer/widgets/promotion_header.dart';
import 'home_promotion_item_widget.dart';
import 'section_header_widget.dart';

class PromotionsSection extends StatefulWidget {
  const PromotionsSection({super.key});

  @override
  State<PromotionsSection> createState() => _PromotionsSectionState();
}

class _PromotionsSectionState extends State<PromotionsSection> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollState();
    });
  }

  void _updateScrollState() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    setState(() {
      _canScrollLeft = currentScroll > 1.0;
      _canScrollRight = currentScroll < (maxScroll - 1.0);
    });

    if (currentScroll >= maxScroll - 50) {
      final provider = context.read<DashboardProvider>();
      if (!provider.isPromotionsLoadingMore) {
        provider.loadMorePromotions();
      }
    }
  }

  void _scroll(bool forward) {
    if (!_scrollController.hasClients) return;
    final orientation = MediaQuery.of(context).orientation;
    final crossAxisCount = orientation == Orientation.landscape ? 3 : 2;
    final double scrollAmount = 1.sw / crossAxisCount;
    
    final double target = forward
        ? _scrollController.offset + scrollAmount
        : _scrollController.offset - scrollAmount;

    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final DateTime date = DateTime.parse(dateStr);
      return DateFormat("dd MMM yyyy").format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getPromotionTitle(dynamic item) {
    // Priority 1: Calculate Discount (Matches Native behavior)
    String discount =
        CommonMethods.findDiscount(item.price, item.promotionPrice);
    if (discount != "0") {
      return "Get $discount% Off";
    }

    // Priority 2: API provided names
    // Fix: Prioritize display_name ("Get 15% Off") over name ("V Can Deals")
    if (item.displayName != null && item.displayName!.isNotEmpty) {
      return item.displayName!;
    }
    if (item.name != null && item.name!.isNotEmpty) {
      return item.name!;
    }
    if (item.title != null && item.title!.isNotEmpty) {
      return item.title!;
    }

    return "Promotion";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.promotionsResponse;
        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        final promotions = response.results!;
        final orientation = MediaQuery.of(context).orientation;
        final crossAxisCount = orientation == Orientation.landscape ? 3 : 2;
        final double cardWidth = (1.sw / crossAxisCount) - 10.w;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeaderWidget(
              title: "Promotions",
              onPrevTap: (promotions.length > crossAxisCount && _canScrollLeft) ? () => _scroll(false) : null,
              onNextTap: (promotions.length > crossAxisCount && _canScrollRight) ? () => _scroll(true) : null,
              itemCount: promotions.length,
              minItemsForNav: crossAxisCount + 1,
            ),
            SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < promotions.length; i++) ...[
                      Builder(builder: (context) {
                        final item = promotions[i];
                        final dateRange =
                            "${_formatDate(item.fromDate)} - ${_formatDate(item.toDate)}";

                        return HomePromotionItemWidget(
                          imageUrl: item.image,
                          title: _getPromotionTitle(item),
                          subtitle: dateRange,
                          width: cardWidth,
                          showShopNow: false,
                          onTap: () {
                            final productProvider =
                                context.read<ProductListProvider>();
                            // Extract product IDs
                            String productIds = "";
                            if (item.products != null &&
                                item.products!.isNotEmpty) {
                              productIds = item.products!
                                  .map((p) => p.productId)
                                  .whereType<String>()
                                  .where((id) => id.isNotEmpty)
                                  .join(',');
                            }

                            // Consolidate Banner logic in a single atomic call
                            productProvider.setBannerNavigation(
                              productIds: productIds,
                              divisionId: item.divisionId,
                              groupId: item.groupId,
                            );

                            // Store Header data in Provider to survive tab switch
                            productProvider.setActiveHeader(
                              PromotionHeader(
                                imageUrl: item.image,
                                title: _getPromotionTitle(item),
                                dateRange: dateRange,
                              ),
                            );

                            // Always reload when visiting Order Now
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                final dashboardProvider = context.read<DashboardProvider>();
                                final profile = dashboardProvider.profileResponse?.results?.firstOrNull;
                                context.read<ProductListProvider>().init(
                                  isTablet: AppTheme.isTablet(context),
                                  profile: profile,
                                );
                              }
                            });
                            // Switch Tab to "Order Now" (which is ProductsListScreen)
                            context.read<DashboardProvider>().setIndex(1);
                          },
                        );
                      }),
                      if (i != promotions.length - 1 || provider.isPromotionsLoadingMore) SizedBox(width: 6.w),
                    ],
                    if (provider.isPromotionsLoadingMore)
                      Container(
                        width: 50.w,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

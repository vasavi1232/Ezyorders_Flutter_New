import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/product_list_provider.dart';
import 'home_promotion_item_widget.dart';
import 'section_header_widget.dart';

class PopularCategoriesSection extends StatefulWidget {
  const PopularCategoriesSection({super.key});

  @override
  State<PopularCategoriesSection> createState() =>
      _PopularCategoriesSectionState();
}

class _PopularCategoriesSectionState extends State<PopularCategoriesSection> {
  late ScrollController _scrollController;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      
      final orientation = MediaQuery.of(context).orientation;
      final crossAxisCount = orientation == Orientation.landscape ? 3 : 2;
      final itemWidth = (1.sw / crossAxisCount) - 10.w + 6.w; // width + gap
      
      if (_scrollController.position.pixels >= 0) {
        int index = (_scrollController.position.pixels / itemWidth).round();
        if (index != _currentIndex) {
          setState(() {
            _currentIndex = index;
          });
        }
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      final bool canLeft = currentScroll > 1.0;
      final bool canRight = currentScroll < (maxScroll - 1.0);
      
      if (_canScrollLeft != canLeft || _canScrollRight != canRight) {
        setState(() {
          _canScrollLeft = canLeft;
          _canScrollRight = canRight;
        });
      }

      if (currentScroll >= maxScroll - 50) {
        final provider = context.read<DashboardProvider>();
        if (!provider.isPopularCategoriesLoadingMore) {
          provider.loadMorePopularCategories();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      setState(() {
         _canScrollRight = maxScroll > 0;
      });
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_scrollController.hasClients) return;

      final provider = context.read<DashboardProvider>();
      final response = provider.popularCategoriesResponse;

      if (response == null ||
          response.results == null ||
          response.results!.isEmpty) {
        return;
      }

      final categories = response.results!
          .where((item) => item != null && item.categoryProductsCount != "0")
          .toList();

      if (categories.isEmpty) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      final orientation = MediaQuery.of(context).orientation;
      final crossAxisCount = orientation == Orientation.landscape ? 3 : 2;
      final itemWidth = (1.sw / crossAxisCount) - 10.w + 6.w;

      double target;
      if (currentScroll >= maxScroll - 5) {
        target = 0.0;
      } else {
        target = currentScroll + itemWidth; // auto-scroll by one item amount
      }

      _scrollController.animateTo(
        target.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goToPage(bool forward, int totalItems) {
    if (!_scrollController.hasClients) return;
    
    final orientation = MediaQuery.of(context).orientation;
    final crossAxisCount = orientation == Orientation.landscape ? 3 : 2;
    
    // Scroll by crossAxisCount items
    int nextIndex = forward ? _currentIndex + crossAxisCount : _currentIndex - crossAxisCount;

    if (nextIndex < 0) nextIndex = 0;
    if (nextIndex >= totalItems) nextIndex = totalItems - 1;

    final itemWidth = (1.sw / crossAxisCount) - 10.w + 6.w;
    _scrollController.animateTo(
      nextIndex * itemWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            final response = provider.popularCategoriesResponse;

            if (response == null ||
                response.results == null ||
                response.results!.isEmpty) {
              return const SizedBox.shrink();
            }

            final categories = response.results!
                .where((item) => item != null && item.categoryProductsCount != "0")
                .toList();

            if (categories.isEmpty) return const SizedBox.shrink();

            final orientation = MediaQuery.of(context).orientation;
            final isLandscape = orientation == Orientation.landscape;
            final crossAxisCount = isLandscape ? 3 : 2;
            final double itemWidth = (1.sw / crossAxisCount) - 10.w;
            
            // Increased height significantly to avoid cutoff in landscape
            final double sectionHeight = isLandscape ? 450.h : 220.h;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeaderWidget(
                  title: "Popular Categories",
                  onPrevTap: (categories.length > crossAxisCount && _canScrollLeft)
                      ? () => _goToPage(false, categories.length)
                      : null,
                  onNextTap: (categories.length > crossAxisCount && _canScrollRight)
                      ? () => _goToPage(true, categories.length)
                      : null,
                  itemCount: categories.length,
                  minItemsForNav: crossAxisCount + 1,
                ),
                SizedBox(
                  height: sectionHeight,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    itemCount: categories.length + (provider.isPopularCategoriesLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) => SizedBox(width: 6.w),
                    itemBuilder: (context, index) {
                      if (index == categories.length) {
                        return Container(
                          width: 50.w,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          ),
                        );
                      }

                      final category = categories[index];
                      if (category == null) return const SizedBox.shrink();

                      return HomePromotionItemWidget(
                        imageUrl: category.image,
                        title: category.groupLevel1 ?? category.popularCategory ?? "",
                        subtitle: _buildSubtitle(category.categoryProductsCount),
                        width: itemWidth,
                          onTap: () {
                            final productProvider = context.read<ProductListProvider>();
                            productProvider.clearFilters();
                            productProvider.setCategory(category.divisionId.toString());
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
                            context.read<DashboardProvider>().setIndex(1);
                          },
                      );
                    },
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            );
          },
        ),
      ],
    );
  }

  String _buildSubtitle(String? count) {
    final value = count ?? "0";
    return value == "1" ? "$value Product" : "$value Products";
  }
}

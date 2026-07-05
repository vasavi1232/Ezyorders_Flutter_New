import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import 'flash_deal_item_widget.dart';
import 'section_header_widget.dart';
import 'product_details_bottom_sheet.dart';
import 'wishlist_category_dialog.dart';
import '../../products/product_details_screen.dart';

class FlashDealsSection extends StatefulWidget {
  const FlashDealsSection({super.key});

  @override
  State<FlashDealsSection> createState() => _FlashDealsSectionState();
}

class _FlashDealsSectionState extends State<FlashDealsSection> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  // Computed once from ScreenUtil — same formula used in build().
  double get _pageSize => (1.sw - 14.w) + 6.w;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollState();
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final double pageSize = _pageSize;

      double target;
      if (currentScroll >= maxScroll - 5) {
        // Loop back to start.
        target = 0.0;
      } else {
        // Snap to the exact start of the next item — never halfway.
        final int nextPage = (currentScroll / pageSize).floor() + 1;
        target = nextPage * pageSize;
      }

      _scrollController.animateTo(
        target.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _updateScrollState() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    setState(() {
      _canScrollLeft = currentScroll > 1.0;
      _canScrollRight = currentScroll < (maxScroll - 1.0);
    });

    if (currentScroll >= maxScroll - 50) {
      final provider = context.read<DashboardProvider>();
      if (!provider.isFlashDealsLoadingMore) {
        provider.loadMoreFlashDeals();
      }
    }
  }

  void _scroll(bool forward) {
    if (!_scrollController.hasClients) return;
    final double pageSize = _pageSize;
    final double target = forward
        ? _scrollController.offset + pageSize
        : _scrollController.offset - pageSize;

    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_updateScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.flashDealsResponse;
        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = response.results!;
        // Same width formula as before — nearly full-screen per item.
        final double itemWidth = 1.sw - 14.w;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeaderWidget(
              title: "Flash Deals",
              onPrevTap: _canScrollLeft ? () => _scroll(false) : null,
              onNextTap: _canScrollRight ? () => _scroll(true) : null,
              itemCount: products.length,
              minItemsForNav: 2,
            ),
            SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < products.length; i++) ...[
                      if (products[i] != null) ...[
                        FlashDealItemWidget(
                          item: products[i]!,
                          width: itemWidth,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                    productId: products[i]!.productId!),
                              ),
                            );
                          },
                          onAddToCart: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ProductDetailsBottomSheet(
                                  product: products[i]!),
                            );
                          },
                          onFavorite: () {
                            final prov = context.read<DashboardProvider>();
                            if (products[i]!.productId != null) {
                              prov.fetchWishlistCategories(
                                  products[i]!.productId!);
                              showDialog(
                                context: context,
                                builder: (context) => WishlistCategoryDialog(
                                    product: products[i]!),
                              );
                            }
                          },
                        ),
                        if (i != products.length - 1 || provider.isFlashDealsLoadingMore) SizedBox(width: 6.w),
                      ],
                    ],
                    if (provider.isFlashDealsLoadingMore)
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

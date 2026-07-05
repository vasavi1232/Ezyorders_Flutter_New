import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../data/models/home_models.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import 'product_item_widget.dart';
import 'section_header_widget.dart';
import 'wishlist_category_dialog.dart';
import 'product_details_bottom_sheet.dart';

class ProductListSection extends StatefulWidget {
  final String title;
  final List<ProductItem?>? products;
  final VoidCallback? onSeeAll;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final String? badgeLabel;

  const ProductListSection({
    super.key,
    required this.title,
    required this.products,
    this.onSeeAll,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.badgeLabel,
  });

  @override
  State<ProductListSection> createState() => _ProductListSectionState();
}

class _ProductListSectionState extends State<ProductListSection> {
  late ScrollController _scrollController;
  int _currentIndex = 0;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      
      final itemWidth = (1.sw / 2) - 10.w + 6.w; // width + gap
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
        if (widget.onLoadMore != null && !widget.isLoadingMore) {
          widget.onLoadMore!();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      setState(() {
         _canScrollRight = maxScroll > 0;
      });
    });
  }

  void _goToPage(bool forward, int totalItems) {
    int nextIndex = forward ? _currentIndex + 2 : _currentIndex - 2;

    if (nextIndex < 0) nextIndex = 0;
    if (nextIndex >= totalItems) nextIndex = totalItems - 1;

    final itemWidth = (1.sw / 2) - 10.w + 6.w;
    _scrollController.animateTo(
      nextIndex * itemWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products == null || widget.products!.isEmpty) {
      return const SizedBox.shrink();
    }

    final products = widget.products!;
    final double itemWidth = (1.sw / 2) - 10.w;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: widget.title,
          onPrevTap: (products.length > 2 && _canScrollLeft)
              ? () => _goToPage(false, products.length)
              : null,
          onNextTap: (products.length > 2 && _canScrollRight)
              ? () => _goToPage(true, products.length)
              : null,
          itemCount: products.length,
          minItemsForNav: 3,
        ),
          SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...List.generate(products.length, (index) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProduct(
                        context,
                        products[index],
                        itemWidth,
                      ),
                      if (index < products.length - 1 || widget.isLoadingMore) SizedBox(width: 6.w),
                    ],
                  );
                }),
                if (widget.isLoadingMore)
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
  }

  Widget _buildProduct(
    BuildContext context,
    ProductItem? product,
    double itemWidth,
  ) {
    if (product == null) return const SizedBox.shrink();

    return ProductItemWidget(
      item: product,
      width: itemWidth,
      onTap: () {
        context.push(AppRoutes.productDetails, extra: product.productId);
      },
      onFavorite: () {
        final provider = context.read<DashboardProvider>();
        if (product.productId != null) {
          provider.fetchWishlistCategories(product.productId!);
          showDialog(
            context: context,
            builder: (context) => WishlistCategoryDialog(product: product),
          );
        }
      },
      onAddToCart: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ProductDetailsBottomSheet(
            product: product,
            badgeLabel: widget.badgeLabel,
          ),
        );
      },
      badgeLabel: widget.badgeLabel,
    );
  }
}

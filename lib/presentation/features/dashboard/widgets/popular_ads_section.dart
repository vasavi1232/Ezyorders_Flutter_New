import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/product_list_provider.dart';
import '../../../../data/models/home_models.dart';
import 'dashboard_banner_item_widget.dart';
import 'section_header_widget.dart';
import '../../products/widgets/product_details_bottom_sheet.dart';

class PopularAdsSection extends StatefulWidget {
  const PopularAdsSection({super.key});

  @override
  State<PopularAdsSection> createState() => _PopularAdsSectionState();
}

class _PopularAdsSectionState extends State<PopularAdsSection> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  void _goToPage(bool forward, int totalPages) {
    int nextPage = forward ? _currentPage + 1 : _currentPage - 1;

    if (nextPage < 0) return;
    if (nextPage >= totalPages) return;

    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.popularAdvertisementsResponse;

        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = response.results!;
        final totalPages = items.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeaderWidget(
              title: "Popular Ads",
              onPrevTap:
                  (totalPages > 1 && _currentPage > 0) ? () => _goToPage(false, totalPages) : null,
              onNextTap:
                  (totalPages > 1 && _currentPage < totalPages - 1) ? () => _goToPage(true, totalPages) : null,
              itemCount: items.length,
              minItemsForNav: 2,
            ),
            SizedBox(
              height: 180.h,
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item == null) return const SizedBox.shrink();

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: DashboardBannerItemWidget(
                      item: item,
                      onTap: () async {
                        if (item.linkImageTo == "Link To Product" &&
                            item.productId != null &&
                            item.productId != "0") {
                          final productListProvider =
                              context.read<ProductListProvider>();
                          await productListProvider
                              .fetchProductDetails(item.productId!);
                          if (context.mounted &&
                              productListProvider.productDetailItem != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ProductDetailsBottomSheet(
                                  product:
                                      productListProvider.productDetailItem!),
                            );
                          }
                        } else if (item.bannerId != null) {
                           // Legacy/Default banner navigation
                          final productProvider =
                              context.read<ProductListProvider>();
                          productProvider.clearFilters();
                          productProvider.setBannerNavigation(banner: item);

                          final profile = provider.profileResponse?.results?.firstOrNull;
                          productProvider.init(
                            isTablet: MediaQuery.of(context).size.width > 600,
                            profile: profile,
                          );

                          context.read<DashboardProvider>().setIndex(1);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

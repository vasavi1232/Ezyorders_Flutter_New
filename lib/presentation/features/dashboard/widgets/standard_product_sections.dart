import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import 'product_list_section.dart';

class BestSellersSection extends StatelessWidget {
  const BestSellersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.bestSellersResponse;
        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        return ProductListSection(
          title: "Best Sellers",
          products: provider.bestSellersResponse?.results,
          badgeLabel: "Best Seller",
          onLoadMore: () => provider.loadMoreBestSellers(),
          isLoadingMore: provider.isBestSellersLoadingMore,
        );
      },
    );
  }
}

class NewArrivalsSection extends StatelessWidget {
  const NewArrivalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.newArrivalsResponse;
        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        return ProductListSection(
          title: "New Arrivals",
          products: provider.newArrivalsResponse?.results,
          badgeLabel: "New Arrivals",
          onLoadMore: () => provider.loadMoreNewArrivals(),
          isLoadingMore: provider.isNewArrivalsLoadingMore,
        );
      },
    );
  }
}

class HotSellingSection extends StatelessWidget {
  const HotSellingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.hotSellingResponse;
        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        return ProductListSection(
          title: "Hot Selling",
          products: provider.hotSellingResponse?.results,
          badgeLabel: "Hot Selling",
          onLoadMore: () => provider.loadMoreHotSelling(),
          isLoadingMore: provider.isHotSellingLoadingMore,
        );
      },
    );
  }
}

class RecentlyAddedSection extends StatelessWidget {
  const RecentlyAddedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final response = provider.recentlyAddedResponse;
        if (response == null ||
            response.results == null ||
            response.results!.isEmpty) {
          return const SizedBox.shrink();
        }

        return ProductListSection(
          title: "Recently Added",
          products: provider.recentlyAddedResponse?.results,
          badgeLabel: null,
          onLoadMore: () => provider.loadMoreRecentlyAdded(),
          isLoadingMore: provider.isRecentlyAddedLoadingMore,
        );
      },
    );
  }
}

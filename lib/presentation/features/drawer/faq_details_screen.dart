import 'package:ezy_orders_flutter/presentation/features/drawer/widgets/faq_detail_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/custom_loader_widget.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../../core/utils/common_methods.dart';

class FAQDetailsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const FAQDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<FAQDetailsScreen> createState() => _FAQDetailsScreenState();
}

class _FAQDetailsScreenState extends State<FAQDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  int _expandedIndex = -1; // -1 means none expanded

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
    // Note: DashboardProvider needs to handle specific category fetching.
    // Android: fetchFAQDetails(page, categoryId as global/param).
    // My DashboardProvider method signature needs check.
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    provider.fetchFAQDetails(widget.categoryId, page);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          CommonMethods.decodeHtmlEntities(widget.categoryName),
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
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
      body: Stack(
        children: [
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              if (provider.isFetchingDrawerData &&
                  provider.faqDetailsResponse == null) {
                return const SizedBox.shrink(); // Overlay handles it
              }

              final details = provider.faqDetailsResponse?.results;

              if (details == null || details.isEmpty) {
                // Android shows "No Data Found" text
                return Center(
                  child: Text(
                    "No Details Found",
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                itemCount:
                    details.length + (provider.isFetchingDrawerData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == details.length) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: CustomLoaderWidget(size: 30.w)),
                    );
                  }

                  final item = details[index];
                  final isExpanded = _expandedIndex == index;

                  return FAQDetailItemWidget(
                    question: item.name ?? "",
                    answer: item.description ?? "",
                    isExpanded: isExpanded,
                    onTap: () {
                      setState(() {
                        if (_expandedIndex == index) {
                          _expandedIndex = -1; // Collapse
                        } else {
                          _expandedIndex = index; // Expand
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              // Initial Load or Pagination Load on empty list (should be covered by initial load condition)
              if (provider.isFetchingDrawerData &&
                  provider.faqDetailsResponse == null) {
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

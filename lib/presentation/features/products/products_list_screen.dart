import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/common_methods.dart';
import '../../providers/product_list_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../dashboard/widgets/wishlist_category_dialog.dart';
import './widgets/product_list_item.dart';
import './widgets/product_grid_item.dart';
import './widgets/sort_dialog.dart';
import './widgets/filter_dialog.dart';
import './widgets/product_details_bottom_sheet.dart';
import './product_details_screen.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/gst_message_widget.dart';

class ProductsListScreen extends StatefulWidget {
  final String? supplierId;
  final String? backNav;
  final String? pageTitle;
  final Widget? headerWidget;
  final bool isStandalone;

  const ProductsListScreen({
    super.key,
    this.supplierId,
    this.backNav,
    this.pageTitle,
    this.headerWidget,
    this.isStandalone = true,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int? _lastTabIndex;

  @override
  void initState() {
    super.initState();
    _lastTabIndex = context.read<DashboardProvider>().currentIndex;
    context.read<DashboardProvider>().addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = context.read<DashboardProvider>();
      final productProvider = context.read<ProductListProvider>();

      // Initialise View Mode (Grid/List) based on device type and API Profile settings
      final profile = dashboardProvider.profileResponse?.results?.isEmpty == true 
          ? null 
          : dashboardProvider.profileResponse?.results?[0];
      
      productProvider.init(isTablet: AppTheme.isTablet(context), profile: profile);
      
      // Ensure search bar is cleared on fresh entry
      _searchController.clear();
    });

    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _onTabChanged() {
    if (!mounted) return;
    final dashboardProvider = context.read<DashboardProvider>();
    final productProvider = context.read<ProductListProvider>();

    // If we just switched TO the products tab from a different tab
    if (dashboardProvider.currentIndex == 1 && _lastTabIndex != 1) {
      _searchController.clear();
      // Ensure provider is also clear (just in case)
      if (productProvider.searchText.isNotEmpty) {
        productProvider.setSearchText("");
        productProvider.fetchProducts(page: 1);
      }
    }
    _lastTabIndex = dashboardProvider.currentIndex;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ProductListProvider>();
      if (!provider.isLoading &&
          provider.productsResponse?.results?.isNotEmpty == true &&
          provider.pageCount < (provider.productsResponse?.totalPages ?? 1)) {
        provider.fetchProducts(page: provider.pageCount + 1, isLoadMore: true);
      }
    }
  }

  @override
  void dispose() {
    // Only dispose if we are the ones who created it (using context.read here is safe)
    // but we MUST remove the listener.
    try {
      context.read<DashboardProvider>().removeListener(_onTabChanged);
    } catch (_) {}
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => const SortDialog(),
    );
  }

  void _showFilterDialog() {
    final provider = context.read<ProductListProvider>();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider<ProductListProvider>.value(
        value: provider,
        child: const FilterDialog(),
      ),
    );
  }

  void _onAddToCart(dynamic product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsBottomSheet(product: product),
    );
  }

  void _onFavorite(dynamic product) async {
    final dashboardProvider = context.read<DashboardProvider>();
    await dashboardProvider.fetchWishlistCategories(product.productId!);
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => WishlistCategoryDialog(product: product),
    );

    if (result != null && mounted) {
      context.read<ProductListProvider>().updateProductFavoriteStatus(
          product.productId!, result ? "Yes" : "No");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.isStandalone ? const CustomBottomNavBar() : null,
      appBar: AppBar(
        title: Text(
          CommonMethods.decodeHtmlEntities(widget.pageTitle ?? "Products"),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4, // 👈 controls shadow intensity
        shadowColor: Colors.black.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: AppTheme.backIconSize(context)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.read<DashboardProvider>().setIndex(0);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Consumer<ProductListProvider>(
            builder: (context, provider, child) {
              final header = widget.headerWidget ?? provider.activeHeaderWidget;
              if (header != null) return header;
              return const SizedBox.shrink();
            },
          ),
          SizedBox(
            height: 12.h,
          ),

          // Product Count Here
          Consumer<ProductListProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    () {
                      final count = provider.productsResponse?.totalRecords ??
                          provider.productsResponse?.resultsCount?.toString();
                      if (count != null && count.isNotEmpty) {
                        return "$count ${count == '1' ? 'Product' : 'Products'} found";
                      }
                      return "Products";
                    }(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          // Toggle Bar (Sort, Filter, Grid/List)
          _buildToggleBar(),

          // Search Bar
          _buildSearchBar(),

          // Main List/Grid
          Expanded(
            child: Consumer<ProductListProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.products.isEmpty) {
                  return Center(child: CustomLoaderWidget(size: 50.w));
                }

                if (provider.products.isEmpty && !provider.isLoading) {
                  return  Center(child: Text("No products found" ,
                    style: TextStyle(
                    color: AppTheme.textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18.sp
                  ),));
                }

                return provider.isGridView
                    ? _buildGridView(provider)
                    : _buildListView(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: isLandscape ? 60.h : 48.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Search products...",
                  hintStyle: TextStyle(
                    color: AppTheme.hintColor,
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 20.sp,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });

                      context.read<ProductListProvider>().setSearchText("");
                      context.read<ProductListProvider>().fetchProducts(page: 1);
                    },
                  )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 10.w,
                  ),
                ),
                onSubmitted: (value) {
                  context.read<ProductListProvider>().setSearchText(value);
                  context.read<ProductListProvider>().fetchProducts(page: 1);
                },
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            height: isLandscape ? 60.h : 45.h,
            width: isLandscape ? 60.h : 45.h,
            decoration: BoxDecoration(
              color: AppTheme.tealColor,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.white, size: 24.sp),
              onPressed: () {
                context
                    .read<ProductListProvider>()
                    .setSearchText(_searchController.text);
                context.read<ProductListProvider>().fetchProducts(page: 1);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Consumer<ProductListProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 2.h),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              Row(
                children: [
                  // Availability Spinner
                  Expanded(
                    flex: 48,
                    child: Container(
                      height: isLandscape ? 55.h : 40.h,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: [
                            "Show Products",
                            "All Products",
                            "Available Products",
                            "Not Available Products"
                          ].contains(CommonMethods.filterSelected)
                              ? CommonMethods.filterSelected
                              : "Show Products",
                          isExpanded: true,
                          items: [
                            "Show Products",
                            "All Products",
                            "Available Products",
                            "Not Available Products"
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.blackColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              provider.onProductAvaSelected(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Sort, Filter, Grid Toggles
                  Expanded(
                    flex: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildIconButton(
                          iconPath: "assets/images/sort_icon.png",
                          fallbackIcon: Icons.sort,
                          onTap: _showSortDialog,
                          isActive: provider.isSortApplied,
                        ),
                        SizedBox(width: 8.w),
                        _buildIconButton(
                          iconPath: "assets/images/filter_icon.png",
                          fallbackIcon: Icons.filter_list,
                          onTap: _showFilterDialog,
                          isActive: provider.isFilterApplied,
                        ),
                        SizedBox(width: 8.w),
                        _buildIconButton(
                          iconPath: provider.isGridView
                              ? "assets/images/listview_icon.png"
                              : "assets/images/gridview_icon.png",
                          fallbackIcon: provider.isGridView
                              ? Icons.view_list
                              : Icons.grid_view,
                          onTap: () =>
                              provider.setGridView(!provider.isGridView),
                          isActive:
                              false, // Toggle button doesn't use "Active" style in Android, acts as toggle
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    String? iconPath,
    required IconData fallbackIcon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Container(
        width: isLandscape ? 50.w : 38.w,
        height: isLandscape ? 50.w : 38.w,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.white,
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: iconPath != null
            ? Image.asset(
                iconPath,
                fit: BoxFit.contain,
                color: isActive
                    ? Colors.white
                    : AppTheme
                        .primaryColor, // applies tint if png is single-color
              )
            : Icon(
                fallbackIcon,
                color: isActive ? Colors.white : AppTheme.primaryColor,
                size: 20.sp,
              ),
      ),
    );
  }

  Widget _buildListView(ProductListProvider provider) {
    final dashboardProvider = context.read<DashboardProvider>();
    final showSoldAs =
        dashboardProvider.profileResponse?.results?[0]?.showSoldAs == "Yes";

    // +1 for GST message header, +1 for loading indicator
    final itemCount = 1 + provider.products.length + (provider.isLoading ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // First item: GST message (scrolls with the list)
        if (index == 0) {
          return GstMessageWidget(padding: EdgeInsets.only(left: 5.w, right: 5.w, bottom: 8.h));
        }

        final productIndex = index - 1;

        if (productIndex == provider.products.length) {
          return Center(
              child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CustomLoaderWidget(size: 30.w),
          ));
        }
        final product = provider.products[productIndex];
        return ProductListItem(
          item: product,
          showSoldAs: showSoldAs,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailsScreen(productId: product.productId!),
              ),
            ).then((_) {
              // Clear search when returning
              _searchController.clear();
              context.read<ProductListProvider>().setSearchText("");
              context.read<ProductListProvider>().fetchProducts(page: 1);
            });
          },
          onAddToCart: (qty) => _onAddToCart(
              product), // Pass qty if we update logic later, currently just trigger
          onFavorite: () => _onFavorite(product),
        );
      },
    );
  }

  Widget _buildGridView(ProductListProvider provider) {
    final dashboardProvider = context.read<DashboardProvider>();
    final showSoldAs =
        dashboardProvider.profileResponse?.results?[0]?.showSoldAs == "Yes";

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    final dimensions = dashboardProvider.profileResponse?.results?.firstOrNull?.productImageDimensions ?? "600x600";
    
    // Significantly increased mainAxisExtent in landscape to fix overlap issues and accommodate taller images/buttons
    double mainAxisExtent = isLandscape ? 500.h : 300.h; 
    if (dimensions.contains("600x400")) {
      mainAxisExtent = isLandscape ? 450.h : 250.h; 
    }

    int crossAxisCount = isLandscape ? 3 : 2;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // GST message as a scrollable header above the grid
        SliverToBoxAdapter(
          child: GstMessageWidget(padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h)),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: mainAxisExtent,
              crossAxisSpacing: 6.w,
              mainAxisSpacing: 6.h,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == provider.products.length) {
                  return Center(child: CustomLoaderWidget(size: 30.w));
                }
                final product = provider.products[index];
                return ProductGridItem(
                  item: product,
                  showSoldAs: showSoldAs,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(productId: product.productId!),
                      ),
                    ).then((_) {
                      // Clear search when returning
                      _searchController.clear();
                      context.read<ProductListProvider>().setSearchText("");
                      context.read<ProductListProvider>().fetchProducts(page: 1);
                    });
                  },
                  onAddToCart: (qty) => _onAddToCart(product),
                  onFavorite: () => _onFavorite(product),
                );
              },
              childCount: provider.products.length + (provider.isLoading ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}

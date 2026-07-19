import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/url_api_key.dart';
import '../../../core/network/image_cache_manager.dart';
import '../../../core/utils/common_methods.dart';
import '../../providers/product_list_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../dashboard/widgets/wishlist_category_dialog.dart';
import './widgets/product_details_bottom_sheet.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../../data/models/product_models.dart';
import '../../../data/models/home_models.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/specials_tooltip.dart';

import '../dashboard/widgets/not_available_dialog.dart';
import '../dashboard/widgets/section_header_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _selectedTabIndex = 0;

  bool _isSameCategoryVisible = false;
  bool _isSimilarProductsVisible = false;
  bool _isInitialVisible = true;
  bool _wasFullyVisible = false;

  final ScrollController _similarScrollController = ScrollController();
  final ScrollController _sameCategoryScrollController = ScrollController();

  bool _canSimilarScrollLeft = false;
  bool _canSimilarScrollRight = true;
  bool _canSameCategoryScrollLeft = false;
  bool _canSameCategoryScrollRight = true;
  final GlobalKey _percentageStripKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductListProvider>().fetchProductDetails(widget.productId);
    });
    _similarScrollController.addListener(_updateSimilarScrollState);
    _sameCategoryScrollController.addListener(_updateSameCategoryScrollState);
  }

  void _updateSimilarScrollState() {
    if (!_similarScrollController.hasClients) return;
    final maxScroll = _similarScrollController.position.maxScrollExtent;
    final currentScroll = _similarScrollController.offset;

    setState(() {
      _canSimilarScrollLeft = currentScroll > 1.0;
      _canSimilarScrollRight = currentScroll < (maxScroll - 1.0);
    });

    if (currentScroll >= maxScroll - 300.w) {
      final provider = context.read<ProductListProvider>();
      if (provider.hasMoreSimilar && !provider.isSimilarLoading) {
        provider.fetchSimilarProducts(widget.productId, isLoadMore: true);
      }
    }
  }

  void _updateSameCategoryScrollState() {
    if (!_sameCategoryScrollController.hasClients) return;
    final maxScroll = _sameCategoryScrollController.position.maxScrollExtent;
    final currentScroll = _sameCategoryScrollController.offset;

    setState(() {
      _canSameCategoryScrollLeft = currentScroll > 1.0;
      _canSameCategoryScrollRight = currentScroll < (maxScroll - 1.0);
    });

    if (currentScroll >= maxScroll - 300.w) {
      final provider = context.read<ProductListProvider>();
      if (provider.hasMoreSameCategory && !provider.isSameCategoryLoading) {
        provider.fetchSameCategoryProducts(widget.productId, isLoadMore: true);
      }
    }
  }

  void _scroll(ScrollController controller, bool forward) {
    if (!controller.hasClients) return;
    final double scrollAmount = 250.w;
    final double target = forward
        ? controller.offset + scrollAmount
        : controller.offset - scrollAmount;

    controller.animateTo(
      target.clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _similarScrollController.removeListener(_updateSimilarScrollState);
    _sameCategoryScrollController.removeListener(_updateSameCategoryScrollState);
    _similarScrollController.dispose();
    _sameCategoryScrollController.dispose();
    super.dispose();
  }

  void _onAddToCart(ProductDetailItem product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsBottomSheet(product: product),
    );
  }

  void _onFavorite(ProductDetailItem product) async {
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
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(
          "Product Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Colors.white, size: AppTheme.backIconSize(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
      body: VisibilityDetector(
        key: Key('product_details_${widget.productId}'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 1.0) {
            if (!_wasFullyVisible) {
              _wasFullyVisible = true;
              if (_isInitialVisible) {
                _isInitialVisible = false;
                return;
              }
              // Trigger refresh whenever screen becomes fully visible (e.g., coming back from Cart)
              context
                  .read<ProductListProvider>()
                  .fetchProductDetails(widget.productId);
            }
          } else {
            _wasFullyVisible = false;
          }
        },
        child: Stack(
          children: [
            Consumer<ProductListProvider>(
            builder: (context, provider, child) {
              // Use specific details loading flag to prevent race conditions from other list fetches
              if (provider.isDetailsLoading && provider.productDetailItem == null) {
                return const SizedBox.shrink(); // Overlay handles loading
              }

              final product = provider.productDetailItem;
              if (product == null) {
                if (provider.isDetailsLoading) return const SizedBox.shrink();
                return const Center(child: Text("Product not found"));
              }

              return SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: AppTheme.borderColor, width: 1.5),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      padding: EdgeInsets.all(8.w),
                      clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductHeader(product),
                        _buildInfoTabs(product),
                        if (product.hasSimilarProducts == "Yes" &&
                            (product.similarProductsCount ?? 0) > 0)
                          _buildSimilarProducts(product),
                        SizedBox(height: 10.h),
                        if (product.hasSameCategoryProducts == "Yes" &&
                            (product.sameCategoryProductsCount ?? 0) > 0)
                          _buildSameCategorySection(product),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Consumer<ProductListProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading || provider.isDetailsLoading) {
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
    ),
   );
  }

  Widget _buildProductHeader(ProductDetailItem product) {
    final bool hasPromotion = product.hasPromotion == "Yes" &&
        product.promotionPrice != null &&
        double.tryParse(product.promotionPrice ?? "0")! > 0;
    
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = AppTheme.isTablet(context);
    final bool isTabletLandscape = isLandscape && isTablet;

    return Padding(
      padding: EdgeInsets.all(15.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () =>
                      _showImagePopup(context, _getImageUrl(product.image)),
                  child: Hero(
                    tag: "product_image_${product.productId}",
                    child: CachedNetworkImage(
                      imageUrl: _getImageUrl(product.image),
                      height: isLandscape ? 450.h : 300.h,
                      fit: BoxFit.contain,
                      cacheManager: ImageCacheManager(),
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[100], height: isLandscape ? 450.h : 300.h),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
                if (product.label != null && product.label!.isNotEmpty)
                  Positioned(
                    top: 10.h,
                    left: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.redColor,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                        product.label!,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          // Title
          Text(
            CommonMethods.decodeHtmlEntities(product.name),
            style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold),
          ),
          // Short Description
          if (product.shortDescription != null &&
              product.shortDescription!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 5.h),
              child: Text(
                CommonMethods.decodeHtmlEntities(product.shortDescription),
                style: TextStyle(
                    color: AppTheme.darkGrayColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
          // Brand
          SizedBox(height: 5.h),
          Text(
            CommonMethods.decodeHtmlEntities(product.brandName),
            style: TextStyle(
                color: Colors.black26,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.h),
          // Pricing
          GestureDetector(
            onTapDown: (details) {
              if (hasPromotion) {
                final String dId = (product.specialId ?? product.discountId ?? "").trim();
                final String dName = (product.specialName ?? product.discountName ?? "").trim();
                
                if (dId.isNotEmpty || dName.isNotEmpty) {
                  final RenderBox? box = _percentageStripKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final position = box.localToGlobal(Offset.zero);
                    final rect = position & box.size;
                    SpecialsTooltip.show(
                      context,
                      discountId: dId,
                      discountName: dName,
                      targetRect: rect,
                    );
                  } else {
                    SpecialsTooltip.show(
                      context,
                      discountId: dId,
                      discountName: dName,
                      tapPosition: details.globalPosition,
                    );
                  }
                }
              }
            },
              child: Row(
              children: [
                if (hasPromotion) ...[
                  Text(
                    _formatPrice(product.price),
                    style: TextStyle(
                        color: AppTheme.darkerGrayColor,
                        fontSize: 16.sp,
                        decoration: TextDecoration.lineThrough),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    _formatPrice(product.promotionPrice),
                    style: TextStyle(
                        color: AppTheme.redColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    key: _percentageStripKey,
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.redColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      "-${CommonMethods.calculateDiscount(product.price, product.promotionPrice)}%",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else
                  Text(
                    _formatPrice(product.price),
                    style: TextStyle(
                        color: AppTheme.darkerGrayColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          SizedBox(height: 5.h),
          // In Stock Status (Native Parity)
          if (product.stockUnlimited != "Yes")
            Align(
              alignment: Alignment.centerLeft,
              child: Builder(builder: (context) {
                if (product.qtyStatus == "Out Of Stock") return const SizedBox.shrink();
                
                String? stockText;
                if (product.qtyStatus == "Low In Stock") {
                  // Fallback to Native behavior
                  stockText = "Low In Stock";
                } else if (product.availableStockQty != null) {
                  stockText = "In Stock : ${product.availableStockQty}";
                }
                
                if (stockText == null) return const SizedBox.shrink();
                
                return Text(
                  stockText,
                  style: TextStyle(
                    color: AppTheme.redColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ),
          SizedBox(height: 15.h),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 160.w,
                child: ElevatedButton(
                  onPressed: (product.qtyStatus == "Out Of Stock" || product.allowToOrder == "No")
                      ? () {}
                      : ((product.supplierAvailable == "1" && product.productAvailable == "1")
                          ? () => _onAddToCart(product)
                          : () {
                              final supplierName = product.supplierAvailable == "0"
                                  ? (product.brandName ?? product.title ?? "")
                                  : (product.name ?? product.title ?? "");
                              
                              showDialog(
                                context: context,
                                builder: (context) => NotAvailableDialog(
                                  supplierName: supplierName,
                                  description: product.notAvailableDaysMessage ?? "",
                                ),
                              );
                            }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (product.qtyStatus == "Out Of Stock" || product.allowToOrder == "No")
                        ? AppTheme.redColor
                        : ((product.supplierAvailable == "1" && product.productAvailable == "1")
                            ? AppTheme.primaryButtonColor
                            : AppTheme.redColor),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.productButtonRadius.r)),
                    minimumSize: Size(double.infinity, isTabletLandscape ? 60.h : (isLandscape ? 48.h : 40.h)),
                  ),
                  child: Text(
                    product.qtyStatus == "Out Of Stock"
                        ? "Out Of Stock"
                        : product.addedToCart == "Yes"
                            ? "Update Cart [${product.addedQty}]"
                            : "Add To Cart",
                    style: TextStyle(color: Colors.white, fontSize: isTabletLandscape ? 14.sp : 14.sp),
                  ),
                ),
              ),
              SizedBox(width: 15.w),
              Consumer<DashboardProvider>(
                builder: (context, dashboard, _) {
                  final allowWishlist = dashboard.profileResponse
                          ?.results?.firstOrNull
                          ?.allowCustomersToAddWishlist ==
                      "Yes";
                  if (!allowWishlist) return const SizedBox.shrink();
                  return InkWell(
                    onTap: () => _onFavorite(product),
                    child: Image.asset(
                      product.isFavourite == "Yes"
                          ? "assets/images/favadded.png"
                          : "assets/images/fav_new.png",
                      width: isTabletLandscape ? 60.h : 30.h,
                      height: isTabletLandscape ? 60.h : 30.h,
                    ),
                  );
                },
              ),
            ],
          ),
          if (product.minimumOrderQty != null &&
              product.minimumOrderQty != "0" &&
              product.minimumOrderQty != "1")
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Text(
                "MOQ : ${product.minimumOrderQty}",
                style: TextStyle(
                    color: AppTheme.redColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTabs(ProductDetailItem product) {
    bool hasSpecs = product.productSpecifications != null &&
        product.productSpecifications!.isNotEmpty;
    int tabCount = hasSpecs ? 2 : 1;

    // Ensure _selectedTabIndex doesn't exceed bounds if specs disappear
    if (!hasSpecs && _selectedTabIndex == 1) {
      _selectedTabIndex = 0;
    }

    return DefaultTabController(
      length: tabCount,
      initialIndex: _selectedTabIndex,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.darkGrayColor,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              onTap: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              tabs: [
                const Tab(text: "Product Details"),
                if (hasSpecs) const Tab(text: "Other Information"),
              ],
            ),
          ),
          _selectedTabIndex == 0
              ? _buildProductDetailsTab(product)
              : _buildOtherInfoTab(product),
        ],
      ),
    );
  }

  bool _hasField(ProductDetailItem product, String fieldName) {
    return product.productFields?.any((f) => f?.name == fieldName) == true;
  }

  Widget _buildProductDetailsTab(ProductDetailItem product) {
    return Padding(
      padding: EdgeInsets.all(15.w),
      child: Column(
        children: [
          if (_hasField(product, 'item') && product.item != null && product.item!.isNotEmpty)
            _buildInfoRow("Item", product.item),
          if (_hasField(product, 'sort_key') && product.sku != null && product.sku!.isNotEmpty)
            _buildInfoRow("Sort Key", product.sku),
          Consumer<DashboardProvider>(
            builder: (context, dashboard, child) {
              final bool showSoldAs = dashboard.profileResponse?.results?.firstOrNull?.showSoldAs == "Yes";
              if (showSoldAs && _hasField(product, 'sold_as') && product.soldAs != null && product.soldAs!.isNotEmpty) {
                return _buildInfoRow("Sold As", product.soldAs);
              }
              return const SizedBox.shrink();
            },
          ),
          if (_hasField(product, 'qty_per_outer') && product.qtyPerOuter != null && product.qtyPerOuter!.isNotEmpty)
            _buildInfoRow("Qty Per Carton", product.qtyPerOuter),
          if (_hasField(product, 'units_shipper') && product.unitsShipper != null && product.unitsShipper!.isNotEmpty)
            _buildInfoRow("Units Inner", product.unitsShipper),
          if (_hasField(product, 'inner_barcode') && product.innerBarcode != null && product.innerBarcode!.isNotEmpty)
            _buildInfoRow("Inner Barcode", product.innerBarcode),
          if (_hasField(product, 'outer_barcode') && product.outerBarcode != null && product.outerBarcode!.isNotEmpty)
            _buildInfoRow("Outer Barcode", product.outerBarcode),
          if (_hasField(product, 'shipper_barcode') && product.shipperBarcode != null && product.shipperBarcode!.isNotEmpty)
            _buildInfoRow("Shipper Barcode", product.shipperBarcode),
          if (_hasField(product, 'primary_barcode') && product.primaryBarcode != null && product.primaryBarcode!.isNotEmpty)
            _buildInfoRow("Primary Barcode", product.primaryBarcode),
          Divider()
        ],
      ),
    );
  }

  Widget _buildOtherInfoTab(ProductDetailItem product) {
    if (product.productSpecifications == null ||
        product.productSpecifications!.isEmpty) {
      return const Center(child: Text("No specification available"));
    }

    // We need to map the specifications to these 4 categories if possible.
    // Assuming the API returns these exact strings in 'specification' or we list all.
    // The user request shows specific buttons: "Important information", "Nutrition information", "Allergens", "Ingredients"
    // Let's filter the specifications to find these.

    final specs = product.productSpecifications!;

    // If we can't find exact matches, we might just list all of them as buttons?
    // Or we stick to the requested 4 and only show if data exists.
    // Let's try to find them. If not found, maybe show "Other"?
    // Actually, looking at the native screenshot, it seems to show these specific categories.
    // I will try to map them. If the API returns different names, this might fail to show.
    // However, I will implement a generic way to show ALL specifications as buttons.
    // This handles dynamic data better.

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.h),
      child: Column(
        children: specs.map((spec) {
          if (spec == null || spec.specification == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 10.h, left: 15.w, right: 15.w),
            child: Align(
              alignment: Alignment.centerLeft, // keeps it left aligned
              child: ElevatedButton(
                onPressed: () => _showOtherInfoDialog(
                    spec.specification!, spec.description ?? ""),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                child: Text(
                  CommonMethods.htmltag(spec.specification),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showOtherInfoDialog(String title, String content) {
    // 1. Clean HTML: Remove explicit width attributes and styles that break mobile layouts
    String cleanedContent = content
        .replaceAll(RegExp(r'width\s*=\s*"[^"]*"', caseSensitive: false), "")
        .replaceAll(RegExp(r"width\s*=\s*'[^']*'", caseSensitive: false), "")
        .replaceAll(RegExp(r'height\s*=\s*"[^"]*"', caseSensitive: false), "")
        .replaceAll(RegExp(r"height\s*=\s*'[^']*'", caseSensitive: false), "")
        .replaceAll(RegExp(r'style\s*=\s*"[^"]*"', caseSensitive: false), "")
        .replaceAll(RegExp(r"style\s*=\s*'[^']*'", caseSensitive: false), "");

    // 2. Decode HTML entities (KEEP TAGS for HTML rendering)
    // Multi-pass decoding handles double-encoded entities from the backend.
    String decodedContent = CommonMethods.decodeHtmlEntities(cleanedContent, stripTags: false);

    // 3. Robust Fallback: Manually parse jumbled Nutrition strings into HTML tables
    if (title.toLowerCase().contains("nutrition") && !decodedContent.contains("<table")) {
       decodedContent = _manualNutritionTableParser(decodedContent);
    }

    /*// 4. Wrap tables for horizontal scrolling if they are large
    if (decodedContent.contains("<table")) {
      // Ensure the table doesn't have internal scrolling styles that interfere
      decodedContent = decodedContent
          .replaceAll('<table', '<table-scroll><table')
          .replaceAll('</table>', '</table></table-scroll>');
    }*/

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // Prevents dull grey/blue tinting in M3
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.blue[900], size: 24.sp),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(12.w),
                child: Html(
                  data: decodedContent,
                  style: {
                    "body": Style(
                      fontSize: FontSize(14.sp),
                      color: Colors.black87,
                      lineHeight: LineHeight(1.4),
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "table": Style(
                      display: Display.table,
                      width: Width.auto(), // Shrink-wrap table
                      border: Border.all(color: AppTheme.white, width: 1.0),
                      margin: Margins.only(bottom: 15.h),
                    ),
                    "tr": Style(
                       border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
                    ),
                    "th": Style(
                      padding: HtmlPaddings.all(10),
                      backgroundColor: Colors.grey.shade50,
                      fontWeight: FontWeight.bold,
                      border: Border.all(color: AppTheme.borderColor, width: 0.5),
                      textAlign: TextAlign.center,
                    ),
                    "td": Style(
                      padding: HtmlPaddings.all(10),
                      border: Border.all(color: AppTheme.borderColor, width: 0.5),
                      verticalAlign: VerticalAlign.middle,
                    ),
                  },
                  extensions: [
                    const TableHtmlExtension(),
                    TagExtension(
                      tagsToExtend: {"table-scroll"},
                      builder: (extensionContext) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Html(
                            data: extensionContext.innerHtml,
                            shrinkWrap: true,
                            style: {
                              "table": Style(
                                display: Display.table,
                                width: Width.auto(),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              "th": Style(
                                padding: HtmlPaddings.all(10),
                                backgroundColor: Colors.grey.shade50,
                                border: Border.all(color: AppTheme.borderColor, width: 0.5),
                                fontWeight: FontWeight.bold,
                              ),
                              "td": Style(
                                padding: HtmlPaddings.all(10),
                                border: Border.all(color: AppTheme.borderColor, width: 0.5),
                              ),
                            },
                            extensions: [const TableHtmlExtension()],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700)),
          Text(CommonMethods.decodeHtmlEntities(value),
              style: TextStyle(
                  color: AppTheme.darkerGrayColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts(ProductDetailItem product) {
    final provider = context.watch<ProductListProvider>();
    final similarProducts = provider.similarProducts ?? [];
    final isLoading = provider.isSimilarLoading;
    final count = product.similarProductsCount ?? 0;
    
    developer.log("UI: Similar section building. Visible: $_isSimilarProductsVisible, Loading: $isLoading, Count: ${similarProducts.length}", name: 'ProductDetailsDebug');
    
    final dashboardProvider = context.read<DashboardProvider>();
    final dimensions = dashboardProvider.profileResponse?.results?.firstOrNull
            ?.productImageDimensions ??
        "600x600";
    
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    double listHeight = isLandscape ? 520.h : 360.h;
    if (dimensions.contains("600x400")) {
      listHeight = isLandscape ? 380.h : 280.h;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: "You Might Also Like",
          onPrevTap: _isSimilarProductsVisible && _canSimilarScrollLeft && !isLoading
              ? () => _scroll(_similarScrollController, false)
              : null,
          onNextTap: _isSimilarProductsVisible && _canSimilarScrollRight && !isLoading
              ? () => _scroll(_similarScrollController, true)
              : null,
          itemCount: _isSimilarProductsVisible ? similarProducts.length : 0,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (!_isSimilarProductsVisible) {
                    setState(() {
                      _isSimilarProductsVisible = true;
                    });
                    context
                        .read<ProductListProvider>()
                        .fetchSimilarProducts(product.productId!);
                  }
                },
                child: RichText(
                  text: TextSpan(
                    text: "$count other products related to this product. ",
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: "Click here",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: " to view",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSimilarProductsVisible)
          SizedBox(
            height: listHeight,
            child: (isLoading && similarProducts.isEmpty)
                ? Center(child: CustomLoaderWidget(size: 40.w))
                : similarProducts.isEmpty 
                  ? Center(child: Text("No similar products found", style: TextStyle(fontSize: 12.sp)))
                  : ListView.builder(
                      controller: _similarScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      itemCount: similarProducts.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == similarProducts.length) {
                          return Container(
                            width: 80.w,
                            alignment: Alignment.center,
                            child: CustomLoaderWidget(size: 30.w),
                          );
                        }
                        final item = similarProducts[index];
                        if (item == null) return const SizedBox.shrink();

                        return SizedBox(
                          width: 170.w,
                          child: _buildProductCard(item),
                        );
                      },
                    ),
          ),
      ],
    );
  }

  Widget _buildSameCategorySection(ProductDetailItem product) {
    final provider = context.watch<ProductListProvider>();
    final sameCategoryProducts = provider.sameCategoryProducts ?? [];
    final isLoading = provider.isSameCategoryLoading;
    final count = product.sameCategoryProductsCount ?? 0;

    developer.log("UI: Same category section building. Visible: $_isSameCategoryVisible, Loading: $isLoading, Count: ${sameCategoryProducts.length}", name: 'ProductDetailsDebug');

    final dashboardProvider = context.read<DashboardProvider>();
    final dimensions = dashboardProvider.profileResponse?.results?.firstOrNull
            ?.productImageDimensions ??
        "600x600";
    
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    double listHeight = isLandscape ? 520.h : 360.h;
    if (dimensions.contains("600x400")) {
      listHeight = isLandscape ? 380.h : 280.h;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          title: "In The Same Category",
          onPrevTap: _isSameCategoryVisible && _canSameCategoryScrollLeft && !isLoading
              ? () => _scroll(_sameCategoryScrollController, false)
              : null,
          onNextTap: _isSameCategoryVisible && _canSameCategoryScrollRight && !isLoading
              ? () => _scroll(_sameCategoryScrollController, true)
              : null,
          itemCount: _isSameCategoryVisible ? sameCategoryProducts.length : 0,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (!_isSameCategoryVisible) {
                    setState(() {
                      _isSameCategoryVisible = true;
                    });
                    context
                        .read<ProductListProvider>()
                        .fetchSameCategoryProducts(product.productId!);
                  }
                },
                child: RichText(
                  text: TextSpan(
                    text: "$count other products in the same category. ",
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: "Click here",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: " to view",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSameCategoryVisible)
          SizedBox(
            height: listHeight,
            child: (isLoading && sameCategoryProducts.isEmpty)
                ? Center(child: CustomLoaderWidget(size: 40.w))
                : sameCategoryProducts.isEmpty
                  ? Center(child: Text("No products found", style: TextStyle(fontSize: 12.sp)))
                  : ListView.builder(
                      controller: _sameCategoryScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      itemCount: sameCategoryProducts.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == sameCategoryProducts.length) {
                          return Container(
                            width: 80.w,
                            alignment: Alignment.center,
                            child: CustomLoaderWidget(size: 30.w),
                          );
                        }
                        final item = sameCategoryProducts[index];
                        if (item == null) return const SizedBox.shrink();

                        return SizedBox(
                          width: 170.w,
                          child: _buildProductCard(item),
                        );
                      },
                    ),
          ),
      ],
    );
  }

  Widget _buildProductCard(ProductItem item) {
    // Standardizing UI to match native Android:
    // 1. Top Stripe: Orange, "Carton (X Units)" or "Each"
    // 2. Image: Standard
    // 3. Details: Title, etc.
    // 4. Action: "Add To Cart" (Orange Rounded) + Heart Icon (Outline/Filled)

    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = AppTheme.isTablet(context);
    final bool isTabletLandscape = isLandscape && isTablet;

    final bool isOutOfStock = item.qtyStatus == "Out Of Stock";
    final bool canAddToCart = item.supplierAvailable == "1" &&
        item.productAvailable == "1" &&
        !isOutOfStock;
    final bool hasPromotion = item.hasPromotion == "Yes" &&
        item.promotionPrice != null &&
        double.tryParse(item.promotionPrice ?? "0")! > 0;

    // Logic for stripe text
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, child) {
        String stripeText = "";
        final bool showSoldAs = dashboard.profileResponse?.results?.firstOrNull?.showSoldAs == "Yes";
        if (showSoldAs) {
          if (item.soldAs == "Each") {
            stripeText = "Each";
          } else if (item.soldAs != null && item.qtyPerOuter != null) {
            stripeText = "${item.soldAs} (${item.qtyPerOuter} Units)";
          } else {
            stripeText = item.soldAs ?? "";
          }
        }

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Card(
            elevation: 2,
            color: Colors.white,
            margin: EdgeInsets.all(2.w),
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailsScreen(productId: item.productId!)),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Stripe (Orange)
                  if (stripeText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.tealColor,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        stripeText,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                  // Image
                  Expanded(
                    flex: isLandscape ? 4 : 5,
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(5.w),
                            child: CachedNetworkImage(
                              imageUrl: _getImageUrl(item.image),
                              fit: BoxFit.contain,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[100]),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        if (item.label != null && item.label!.isNotEmpty)
                          Positioned(
                            top: 5.h,
                            left: 5.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                  color: AppTheme.redColor,
                                  borderRadius: BorderRadius.circular(3.r)),
                              child: Text(item.label!,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Details
                  Expanded(
                    flex: isLandscape ? 9 : 7,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              CommonMethods.decodeHtmlEntities(
                                  item.brandName ?? ""),
                              style: TextStyle(
                                  color: AppTheme.darkerGrayColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800),
                              maxLines: 1),
                          Text(CommonMethods.decodeHtmlEntities(item.title ?? ""),
                              style: TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),

                          // Price
                          SizedBox(height: 5.h),
                          if (!hasPromotion)
                            Text(_formatPrice(item.price),
                                style: TextStyle(
                                    color: AppTheme.darkerGrayColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800))
                          else
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4.w,
                              runSpacing: 2.h,
                              children: [
                                Text(_formatPrice(item.price),
                                    style: TextStyle(
                                        color: AppTheme.darkerGrayColor,
                                        fontSize: 12.sp,
                                        decoration: TextDecoration.lineThrough)),
                                Text(_formatPrice(item.promotionPrice),
                                    style: TextStyle(
                                        color: AppTheme.redColor,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppTheme.redColor,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    "-${CommonMethods.calculateDiscount(item.price, item.promotionPrice)}%",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          if (item.stockUnlimited != "Yes")
                            Builder(builder: (context) {
                              if (item.qtyStatus == "Out Of Stock") return const SizedBox.shrink();

                              String? stockText;
                              if (item.qtyStatus == "Low In Stock") {
                                stockText = "Low In Stock";
                              } else if (item.availableStockQty != null) {
                                stockText = "In Stock : ${item.availableStockQty}";
                              }

                              if (stockText == null) return const SizedBox.shrink();

                              return Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Text(
                                  stockText,
                                  style: TextStyle(
                                      color: AppTheme.redColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            }),

                          const Spacer(),

                          // Action Row: Add To Cart + Heart
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: isOutOfStock
                                      ? null
                                      : (canAddToCart
                                          ? () => _onAddToCart(ProductDetailItem.fromJson(item.toJson()))
                                          : () {
                                              final supplierName = item.supplierAvailable == "0"
                                                  ? (item.brandName ?? item.title ?? "")
                                                  : (item.name ?? item.title ?? "");
                                              
                                              showDialog(
                                                context: context,
                                                builder: (context) => NotAvailableDialog(
                                                  supplierName: supplierName,
                                                  description: item.notAvailableDaysMessage ?? "",
                                                ),
                                              );
                                            }),                                  child: Container(
                                    height: isTabletLandscape ? 50.h : (isLandscape ? 50.h : 34.h),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: canAddToCart
                                          ? AppTheme.primaryButtonColor
                                          : AppTheme.redColor,
                                      borderRadius:
                                          BorderRadius.circular(20.r), // Rounded
                                    ),
                                    child: Text(
                                        isOutOfStock
                                            ? "Out Of Stock"
                                            : "Add To Cart",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Consumer<DashboardProvider>(
                                builder: (context, dashboard, _) {
                                  final allowWishlist = dashboard.profileResponse
                                          ?.results?.firstOrNull
                                          ?.allowCustomersToAddWishlist ==
                                      "Yes";
                                  if (!allowWishlist) return const SizedBox.shrink();
                                  return InkWell(
                                    onTap: () {
                                      _onFavorite(
                                          ProductDetailItem.fromJson(item.toJson()));
                                    },
                                    child: Icon(
                                      item.isFavourite == "Yes"
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: item.isFavourite == "Yes"
                                          ? AppTheme.redColor
                                          : AppTheme.primaryColor,
                                      size: isTabletLandscape ? 30.sp : 26.sp,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    );
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    return "${UrlApiKey.mainUrl}$path";
  }

  String _formatPrice(String? price) {
    return CommonMethods.setPriceFormatString(price);
  }

  void _showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        final bool isTabletLandscape = MediaQuery.of(context).size.shortestSide >= 600 &&
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: 1.sw,
                  height: 1.sh,
                  cacheManager: ImageCacheManager(),
                  placeholder: (context, url) =>
                      Center(child: CustomLoaderWidget(size: 50.w)),
                  errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50),
                ),
              ),
              Positioned(
                top: 10.h,
                right: 20.w,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size:  30.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Manual parser for jumbled/plaintext nutrition data
  String _manualValueParser(String rawText, String name) {
    // Regex to match the nutrient name followed by 2 values
    // Matches: "Energy 401.0kJ 2190.0kJ" or "Protein 0.9g 4.6g" or "Fat, Total 4.9g 26.8g"
    final cleanName = name.replaceAll(RegExp(r'[,.\-]'), r'.*?');
    final pattern = "$cleanName\\s+([0-9.<>\- ]+?[a-zA-Z%]+|(?:\s*-\s*))\\s+([0-9.<>\- ]+?[a-zA-Z%]+|(?:\s*-\s*))";
    final regex = RegExp(pattern, caseSensitive: false);
    final match = regex.firstMatch(rawText);
    if (match != null) {
      return """
        <tr style="border-bottom:1px solid #ddd;">
          <td style="padding:10px; border-right:1px solid #ddd; font-weight:bold; font-size:12px;">${name.replaceAll("-", "")}</td>
          <td style="padding:10px; border-right:1px solid #ddd; text-align:center; font-size:12px;">${match.group(1)?.trim() ?? '-'}</td>
          <td style="padding:10px; text-align:center; font-size:12px;">${match.group(2)?.trim() ?? '-'}</td>
        </tr>
      """;
    }
    return "";
  }

  String _manualNutritionTableParser(String rawText) {
    if (rawText.isEmpty) return rawText;

    // 1. Extract Metadata (Servings per pack & Serving size)
    final metaRegex = RegExp(r"Servings per pack\s*(.*?)\s*Serving size\s*(.*?)(\s|$)", caseSensitive: false);
    final metaMatch = metaRegex.firstMatch(rawText);
    String metaTable = "";
    if (metaMatch != null) {
      metaTable = """
        <table style="width:100%; border:1px solid #ddd; border-collapse:collapse; margin-bottom:15px;">
          <tr style="background-color:#f8f9fa; border-bottom:1px solid #ddd;">
             <th style="padding:10px; border-right:1px solid #ddd; text-align:left; font-size:12px;">Servings per pack</th>
             <th style="padding:10px; text-align:left; font-size:12px;">Serving size</th>
          </tr>
          <tr>
             <td style="padding:10px; border-right:1px solid #ddd; font-size:13px;">${metaMatch.group(1)}</td>
             <td style="padding:10px; font-size:13px;">${metaMatch.group(2)}</td>
          </tr>
        </table>
      """;
    }

    // 2. Extract Nutrients
    final nutrients = [
      "Energy", "Protein", "Fat, Total", "-Saturated", "Carbohydrate",
      "-Sugars", "Dietary Fibre", "Sodium"
    ];

    String rows = "";
    for (var n in nutrients) {
      rows += _manualValueParser(rawText, n);
    }

    if (rows.isEmpty && metaTable.isEmpty) return rawText;

    String nutritionTable = """
      <table style="width:100%; border:1px solid #ddd; border-collapse:collapse;">
        <tr style="background-color:#f8f9fa; border-bottom:1px solid #ddd;">
          <th style="padding:10px; border-right:1px solid #ddd; width:40%;"></th>
          <th style="padding:10px; border-right:1px solid #ddd; width:30%; font-size:13px;">Per Serving</th>
          <th style="padding:10px; width:30%; font-size:13px;">Per 100g</th>
        </tr>
        $rows
      </table>
    """;

    // 3. Extract Notes
    final notesRegex = RegExp(r"(Quantities stated above.*)", caseSensitive: false);
    final notesMatch = notesRegex.firstMatch(rawText);
    String notes = "";
    if (notesMatch != null) {
      notes = "<p style='margin-top:15px; font-size:13px; color:#555;'>${notesMatch.group(1)}</p>";
    }

    return """
      <div style="font-family:sans-serif;">
        $metaTable
        $nutritionTable
        $notes
      </div>
    """;
  }
}

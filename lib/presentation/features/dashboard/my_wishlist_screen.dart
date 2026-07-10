import 'package:ezy_orders_flutter/presentation/features/dashboard/widgets/wishlist_item_widget.dart';
import 'package:ezy_orders_flutter/presentation/features/dashboard/widgets/remove_wishlist_item_dialog.dart';
import 'package:ezy_orders_flutter/presentation/features/dashboard/widgets/product_details_bottom_sheet.dart';
import 'package:ezy_orders_flutter/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../config/routes/app_routes.dart';
import '../../widgets/gst_message_widget.dart';

class MyWishlistScreen extends StatefulWidget {
  const MyWishlistScreen({super.key});

  @override
  State<MyWishlistScreen> createState() => _MyWishlistScreenState();
}

class _MyWishlistScreenState extends State<MyWishlistScreen> {
  @override
  void initState() {
    super.initState();
    // Initial fetch is now handled by VisibilityDetector for consistency
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppTheme.white,
      bottomNavigationBar: const CustomBottomNavBar(),
      appBar: AppBar(
        elevation: 4, // 👈 controls shadow intensity
        shadowColor: Colors.black.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        title: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            return Text(
              provider.profileResponse?.results?.firstOrNull
                      ?.wishlistPageHeading ??
                  "My Favourites",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),

        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Colors.white, size: AppTheme.backIconSize(context)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
      ),
      body: VisibilityDetector(
        key: const Key('my-wishlist-screen'),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction == 1.0) {
            context.read<DashboardProvider>().fetchMyWishlist();
          }
        },
        child: Stack(
        children: [
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              if (provider.isFetchingMyWishlist &&
                  provider.myWishlistItems.isEmpty) {
                return const SizedBox.shrink(); // Overlay handles it
              }

              if (provider.myWishlistItems.isEmpty &&
                  provider.myWishlistCategories.isEmpty) {
                return Center(
                  child: Text(
                    "No Products added",
                    style: TextStyle(fontSize: 14.sp, color: AppTheme.primaryColor,fontWeight: FontWeight.w800),
                  ),
                );
              }

              return Column(
                children: [
                  // Horizontal Categories List
                  if (provider.myWishlistCategories.isNotEmpty)
                    Container(
                      height: isLandscape ? 55.h : 40.h,
                      margin: EdgeInsets.symmetric(vertical: 20.h),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        itemCount: provider.myWishlistCategories.length +
                            1, // +1 for "All"
                        itemBuilder: (context, index) {
                          String catName = "";
                          String catId = "";

                          // "All" Tab
                          if (index == 0) {
                            catName =
                                "All Items"; // Or a specific label if Android has one, e.g. "All"
                            catId = "";
                          } else {
                            final cat =
                                provider.myWishlistCategories[index - 1];
                            catName = cat.categoryName ?? "Unknown";
                            catId = cat.categoryId?.toString() ?? "";
                          }

                          final isSelected =
                              provider.selectedWishlistCategoryId == catId;

                          return InkWell(
                            onTap: () {
                              provider.setSelectedWishlistCategory(catId);
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 10.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.white
                                    : AppTheme.white,
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.tealColor
                                      : AppTheme.hintColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                catName,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.tealColor
                                      : AppTheme.blackColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Product List (GST message scrolls as first item)
                          Expanded(
                            child: provider.myWishlistItems.isEmpty
                                ? Center(
                                    child: Text(
                                      "No items in this category",
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppTheme.darkGrayColor),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: 1 + provider.myWishlistItems.length, // +1 for GST message
                                    padding: EdgeInsets.only(bottom: 20.h),
                                    itemBuilder: (context, index) {
                                      // First item: GST message (scrolls with the list)
                                      if (index == 0) {
                                        return GstMessageWidget(padding: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 8.h));
                                      }

                                      final productIndex = index - 1;
                                      final item = provider.myWishlistItems[productIndex];

                                      // Determine Category Name display logic for parity
                                      String? displayCatName;
                                      if (provider.selectedWishlistCategoryId.isEmpty) {
                                        // Find category name for this item
                                        try {
                                          final cat =
                                              provider.myWishlistCategories.firstWhere(
                                            (c) =>
                                                c.categoryId.toString() ==
                                                item.wishlistCategoryId,
                                          );
                                          displayCatName = cat.categoryName;
                                        } catch (e) {
                                          displayCatName = "";
                                        }
                                      } else {
                                        // Android implementation hides it if category is selected.
                                        displayCatName = null;
                                      }

                                      final isSelected = provider.isWishlistItemSelected(item.wishlistId ?? "");

                                      return WishlistItemWidget(
                                        item: item,
                                        width: 1.sw, // Full width for list item
                                        isSelected: isSelected,
                                        categoryName: displayCatName,
                                        selectedQuantity: provider.getSelectedWishlistQuantity(item.wishlistId ?? ""),
                                        
                                        onIncrementQuantity: () {
                                            if (item.wishlistId != null) {
                                                provider.incrementSelectedWishlistQuantity(item.wishlistId!);
                                            }
                                        },
                                        onDecrementQuantity: () {
                                            if (item.wishlistId != null) {
                                                provider.decrementSelectedWishlistQuantity(item.wishlistId!);
                                            }
                                        },

                                        onSelect: () {
                                          if (item.wishlistId != null) {
                                            provider.toggleWishlistItemSelection(
                                                item.wishlistId!);
                                          }
                                        },

                                        onDelete: () {
                                          if (item.wishlistId != null) {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => RemoveWishlistItemDialog(
                                                item: item,
                                                categoryName: displayCatName,
                                                onDelete: () {
                                                  provider.deleteWishlistItem(
                                                      item.wishlistId!);
                                                },
                                              ),
                                            );
                                          }
                                        },

                                        onAddToCart: () {
                                          // Parity: Opens Bottom Sheet
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (ctx) => ProductDetailsBottomSheet(
                                                product: item),
                                          ).then((_) {
                                            provider.fetchMyWishlist();
                                          });
                                        },

                                        onTap: () {
                                          context.push(AppRoutes.productDetails,
                                              extra: item.productId);
                                        },
                                      );
                                    },
                                  ),
                          ),
                          
                          // Global Add To Cart / Update Cart Button (Visible when items selected)
                          if (provider.myWishlistItems.any((item) => provider.isWishlistItemSelected(item.wishlistId ?? "")))
                            Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                                decoration: BoxDecoration(
                                    color: AppTheme.white,
                                    boxShadow: [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(0, -2)
                                        )
                                    ]
                                ),
                                child: InkWell(
                                    onTap: () async {
                                        final success = await provider.addSelectedWishlistItemsToCart();
                                        if (context.mounted) {
                                            if (success) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text("Cart updated successfully"), backgroundColor: AppTheme.tealColor,)
                                                );
                                            } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(provider.actionError?.isNotEmpty == true ? provider.actionError! : "Failed to add items to cart"), backgroundColor: AppTheme.redColor,)
                                                );
                                              }
                                        }
                                    },
                                    child: Container(
                                        height: 40.h,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: AppTheme.primaryButtonColor,
                                            borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: Builder(
                                            builder: (context) {
                                                // Check if any selected item is already in cart to determine text
                                                bool anyInCart = provider.myWishlistItems.where(
                                                    (item) => provider.isWishlistItemSelected(item.wishlistId ?? "")
                                                ).any((item) => item.addedToCart == "Yes");
                                                
                                                return Text(
                                                    anyInCart ? "Update Cart" : "Add To Cart",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14.sp,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                );
                                            },
                                        ),
                                    ),
                                ),
                            )
                        ],
                      );
                    },
                  ),
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              if (provider.isFetchingMyWishlist || provider.isLoading) {
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
}

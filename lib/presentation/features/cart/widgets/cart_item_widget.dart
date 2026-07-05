import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../../data/models/cart_models.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/custom_loader_widget.dart';
import '../../../widgets/specials_tooltip.dart';
import 'cart_update_bottom_sheet.dart';

class CartItemWidget extends StatefulWidget {
  final CartProduct item;

  const CartItemWidget({super.key, required this.item});

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showQuantityPicker(BuildContext context) {
    int minQty = int.tryParse(widget.item.minimumOrderQty ?? "1") ?? 1;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CartUpdateBottomSheet(
        item: widget.item,
        initialQty: widget.item.qty ?? minQty,
        minQty: minQty,
        onUpdate: (newQty) async {
          final dashboardProvider = context.read<DashboardProvider>();
          await context
              .read<CartProvider>()
              .updateCartItem(widget.item, newQty.toString());
          if (mounted) {
            dashboardProvider.setCartCount(CommonMethods.cartCount);
          }
        },
        onDelete: () async {
          final dashboardProvider = context.read<DashboardProvider>();
          await context.read<CartProvider>().deleteCartItem(widget.item);
          if (mounted) {
            dashboardProvider.setCartCount(CommonMethods.cartCount);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: "${UrlApiKey.mainUrl}${widget.item.image}",
                width: 80.w,
                height: 80.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(child: CustomLoaderWidget(size: 30.w)),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            SizedBox(width: 10.w),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.brandName != null &&
                      widget.item.brandName!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        CommonMethods.htmltag(widget.item.brandName),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CommonMethods.htmltag(widget.item.title),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Price Section
                  (() {
                    final cartResult = context.read<CartProvider>().cartResult;
                    final bool showGst =
                        cartResult?.showPriceIncludingGst == "Yes";
                    double gstVal = double.tryParse(widget.item.gstPrice ?? "0") ?? 0;

                    double normal =
                        double.tryParse(widget.item.normalPrice ?? "0") ?? 0;
                    double sale = double.tryParse(widget.item.salePrice ?? "0") ?? 0;

                    if (showGst) {
                      normal += gstVal;
                      sale += gstVal;
                    }

                    // A discount exists if sale price is strictly less than normal price
                    bool hasDiscount = sale > 0 && (normal - sale) > 0.01;

                    return GestureDetector(
                      onTapDown: (details) {
                        if (hasDiscount &&
                            (widget.item.specialId != null ||
                                widget.item.specialName != null)) {
                          SpecialsTooltip.show(
                            context,
                            discountId: widget.item.specialId ?? "",
                            discountName: widget.item.specialName ?? "",
                            tapPosition: details.globalPosition,
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              CommonMethods.setPriceFormatString(normal.toString()),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.darkGrayColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(height: 2.h),
                          ],
                          Row(
                            children: [
                              Text(
                                hasDiscount
                                    ? CommonMethods.setPriceFormat(sale)
                                    : (sale > 0
                                        ? CommonMethods.setPriceFormat(sale)
                                        : CommonMethods.setPriceFormat(normal)),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkerGrayColor,
                                ),
                              ),
                              if (hasDiscount) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: AppTheme.redColor,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                  child: Text(
                                    "-${CommonMethods.calculateDiscount(normal.toString(), sale.toString())}%",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  })(),

                  SizedBox(height: 4.h),
                  Consumer<DashboardProvider>(
                    builder: (context, dashboard, child) {
                      final bool showSoldAs =
                          dashboard.profileResponse?.results?[0]?.showSoldAs ==
                              "Yes";
                      if (!showSoldAs) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5.h),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Ordered As : ",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: widget.item.orderedAs ?? "",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Qty Controls & Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Qty Control
                      InkWell(
                        onTap: () => _showQuantityPicker(context),
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          height: 32.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                child: Icon(Icons.remove,
                                    size: 16.sp, color: Colors.grey),
                              ),
                              SizedBox(
                                width: 30.w,
                                child: Center(
                                  child: Text(
                                    widget.item.qty.toString(),
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                child: Icon(Icons.add,
                                    size: 16.sp, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Delete
                      InkWell(
                        onTap: () async {
                          await context
                              .read<CartProvider>()
                              .deleteCartItem(widget.item);
                          if (context.mounted) {
                            context
                                .read<DashboardProvider>()
                                .setCartCount(CommonMethods.cartCount);
                          }
                        },
                        child: Icon(Icons.delete,
                            color: AppTheme.redColor, size: 24.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


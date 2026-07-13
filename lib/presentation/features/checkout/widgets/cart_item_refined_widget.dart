import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/cart_models.dart';
import '../../../../core/constants/app_theme.dart';
import 'package:ezy_orders_flutter/core/utils/common_methods.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../widgets/custom_loader_widget.dart';
import '../../../widgets/specials_tooltip.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../cart/widgets/cart_update_bottom_sheet.dart';

class CartItemRefinedWidget extends StatefulWidget {
  final CartProduct item;
  final bool showHeader;
  final bool showBrand;
  final String brandName;
  final String brandId;
  final Function(String newQty) onUpdateQty;
  final VoidCallback onDelete;

  const CartItemRefinedWidget({
    super.key,
    required this.item,
    this.showHeader = false,
    this.showBrand = true,
    required this.brandName,
    required this.brandId,
    required this.onUpdateQty,
    required this.onDelete,
  });

  @override
  State<CartItemRefinedWidget> createState() => _CartItemRefinedWidgetState();
}

class _CartItemRefinedWidgetState extends State<CartItemRefinedWidget> {
  final GlobalKey _percentageStripKey = GlobalKey();

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
        onUpdate: (newQty) {
          widget.onUpdateQty(newQty.toString());
        },
        onDelete: widget.onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletLandscape =
        MediaQuery.of(context).size.shortestSide >= 600 &&
            MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) _buildHeader(context),
        Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.zero,
          color: Colors.white,
          child: Column(
            children: [
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r)),
                margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand Row
                      if (widget.showBrand) ...[
                        Text(
                          CommonMethods.htmltag(widget.brandName),
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 5.h),
                      ],

                      // Image, Info, and Delete Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image
                          Container(
                            width: 60.w,
                            height: 60.h,
                            alignment: Alignment.center,
                            child: _buildImage(widget.item.image),
                          ),
                          SizedBox(width: 10.w),

                          // Center Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CommonMethods.htmltag(
                                      widget.item.title?.toUpperCase() ?? ""),
                                  style: TextStyle(
                                      color: AppTheme.textColor,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                GestureDetector(
                                  onTapDown: (details) {
                                    double n = double.tryParse(
                                            widget.item.normalPrice ?? "0") ??
                                        0;
                                    double s = double.tryParse(
                                            widget.item.salePrice ?? "0") ??
                                        0;
                                    bool hasDiscount = s > 0 && s < n;

                                    if (hasDiscount) {
                                      final String dId =
                                          (widget.item.specialId ?? "").trim();
                                      final String dName =
                                          (widget.item.specialName ?? "")
                                              .trim();

                                      if (dId.isNotEmpty || dName.isNotEmpty) {
                                        final RenderBox? box =
                                            _percentageStripKey.currentContext
                                                ?.findRenderObject() as RenderBox?;
                                        if (box != null) {
                                          final position =
                                              box.localToGlobal(Offset.zero);
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Price Section - Row based as requested
                                      Row(
                                        children: [
                                          if (() {
                                            double n = double.tryParse(
                                                    widget.item.normalPrice ??
                                                        "0") ??
                                                0;
                                            double s = double.tryParse(
                                                    widget.item.salePrice ??
                                                        "0") ??
                                                0;
                                            return s > 0 && s < n;
                                          }()) ...[
                                            Text(
                                              CommonMethods
                                                  .setPriceFormatString(
                                                      widget.item.normalPrice),
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13.sp,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(width: 8.w),
                                          ],
                                          Text(
                                            CommonMethods.setPriceFormatString(
                                                (double.tryParse(widget
                                                                    .item.salePrice ??
                                                                "0") ??
                                                            0) >
                                                        0
                                                    ? widget.item.salePrice
                                                    : widget.item.normalPrice),
                                            style: TextStyle(
                                                color: AppTheme.darkerGrayColor,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      if (() {
                                        double n = double.tryParse(
                                                widget.item.normalPrice ??
                                                    "0") ??
                                            0;
                                        double s = double.tryParse(
                                                widget.item.salePrice ??
                                                    "0") ??
                                            0;
                                        return s > 0 && s < n;
                                      }())
                                        Container(
                                          key: _percentageStripKey,
                                          margin: EdgeInsets.only(top: 5.h),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5.w, vertical: 2.h),
                                          color: AppTheme.redColor,
                                          child: Text(
                                            "-${CommonMethods.calculateDiscount(widget.item.normalPrice, widget.item.salePrice)}%",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Delete Icon
                          if (!isTabletLandscape)
                            InkWell(
                              onTap: widget.onDelete,
                              child: Padding(
                                padding: EdgeInsets.all(5.w),
                                child: Icon(Icons.delete,
                                    color: AppTheme.redColor, size: 24.sp),
                              ),
                            ),
                        ],
                      ),

                      // Bottom Row: Ordered As and Qty
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Ordered As
                          Consumer<DashboardProvider>(
                            builder: (context, dashboard, child) {
                              final bool showSoldAs = dashboard
                                      .profileResponse?.results?[0]?.showSoldAs ==
                                  "Yes";
                              if (!showSoldAs) return const SizedBox.shrink();

                              if (widget.item.orderedAs != null &&
                                  widget.item.orderedAs!.isNotEmpty) {
                                return Padding(
                                  padding: EdgeInsets.only(top: 10.h),
                                  child: Row(
                                    children: [
                                      Text("Ordered As : ",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w800)),
                                      Text(
                                          widget.item.orderedAs ??
                                              widget.item.soldAs ??
                                              "Each",
                                          style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          Row(
                            children: [
                              InkWell(
                                onTap: () => _showQuantityPicker(context),
                                borderRadius: BorderRadius.circular(20.r),
                                child: Container(
                                  height: isTabletLandscape ? 70.h : 32.h,
                                  margin: EdgeInsets.only(top: 5.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border:
                                        Border.all(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.w),
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
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10.w),
                                        child: Icon(Icons.add,
                                            size: 16.sp, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isTabletLandscape) ...[
                                SizedBox(width: 10.w),
                                InkWell(
                                  onTap: widget.onDelete,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 5.h),
                                    child: Icon(Icons.delete,
                                        color: AppTheme.redColor, size: 24.sp),
                                  ),
                                ),
                              ],
                            ],
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
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox.shrink();
  }

  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return Icon(Icons.image_not_supported, color: Colors.grey);
    }
    String finalUrl = path;
    if (!path.startsWith("http")) {
      finalUrl = "${UrlApiKey.mainUrl}$path";
    }

    return CachedNetworkImage(
      imageUrl: finalUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) =>
          Center(child: CustomLoaderWidget(size: 30.w)),
      errorWidget: (context, url, error) =>
          Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

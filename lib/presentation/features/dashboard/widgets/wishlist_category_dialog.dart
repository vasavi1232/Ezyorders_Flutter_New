import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/home_models.dart';
import '../../../../data/models/wishlist_models.dart';
import '../../../providers/dashboard_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class WishlistCategoryDialog extends StatefulWidget {
  final ProductItem product;

  const WishlistCategoryDialog({super.key, required this.product});

  @override
  State<WishlistCategoryDialog> createState() => _WishlistCategoryDialogState();
}

class _WishlistCategoryDialogState extends State<WishlistCategoryDialog> {
  final TextEditingController _newCategoryController = TextEditingController();
  bool _isAddingNewList = false;
  String? _initialSelectedCatIds; // Changed from "" to null

  @override
  void initState() {
    super.initState();
    // Do not initialize here because provider.wishlistCategories might still be loading!
  }

  String _getCatIdsString(List<WishlistCategory?>? cats) {
    if (cats == null || cats.isEmpty) return "";
    // Replicating Android logic: comma separated IDs for selected items
    return cats
        .where((c) => c?.isSelected == true)
        .map((c) => c?.categoryId)
        .join(",");
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Orange Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.tealColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add To Wishlist",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 24.sp, color: Colors.white),
                )
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Product Name (Blue)
                Text(
                  widget.product.title ?? "Product Name",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                SizedBox(height: 8.h),

                // Note (Red) for Remove
                Text(
                  "Note : To remove product from Wishlist then unselect and save",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.redColor,
                  ),
                ),
                SizedBox(height: 16.h),

                // Categories List
                Consumer<DashboardProvider>(
                  builder: (context, provider, child) {
                    final categories = provider.wishlistCategories;
                    if (categories == null || categories.isEmpty) {
                      return const SizedBox();
                    }

                    // Initialize the initial selection state ONCE when data is actually available
                    if (_initialSelectedCatIds == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _initialSelectedCatIds =
                                _getCatIdsString(categories);
                          });
                        }
                      });
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 180.h),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return CheckboxListTile(
                            title: Text(
                              category?.categoryName ?? "",
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            value: category?.isSelected ?? false,
                            onChanged: (val) {
                              provider
                                  .toggleWishlistCategory(category?.categoryId);
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: AppTheme.tealColor,
                          );
                        },
                      ),
                    );
                  },
                ),

                SizedBox(height: 12.h),

                // Add New List Toggle Logic
                // Add New List Toggle Logic
                if (!_isAddingNewList)
                  Center(
                    child: SizedBox(
                      width: 140.w,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isAddingNewList = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryButtonColor,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                        child: Text(
                          "+ Add New List",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCategoryController,
                          decoration: InputDecoration(
                            hintText: "Enter Wishlist Name",
                            hintStyle:
                                TextStyle(fontSize: 12.sp, color: AppTheme.hintColor),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8.h, horizontal: 8.w),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.r),
                              borderSide: BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Cancel (X) Button aka 'removefav_lay' logic
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isAddingNewList = false;
                            _newCategoryController.clear();
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(5.w),
                          decoration: BoxDecoration(
                            color: AppTheme.redColorOpacity10,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 16.sp, color: AppTheme.redColor),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 16.h),

                // Buttons: Save (Orange) & Close (Grey)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Save Button
                    SizedBox(
                      width: 100.w,
                      child: ElevatedButton(
                        onPressed: () => _submitUpdate(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryButtonColor,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                        child: Text(
                          "Save",
                          style:
                              TextStyle(fontSize: 14.sp, color: Colors.white , fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),

                    // Close Button
                    SizedBox(
                      width: 100.w,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryButtonColor,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                        child: Text(
                          "Close",
                          style:
                              TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitUpdate(BuildContext context) async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);

    String currentCatIds = _getCatIdsString(provider.wishlistCategories);
    String categoryVal = _newCategoryController.text.trim();

    // Android Logic: Block save if they typed no text AND the category selection hasn't changed.
    // _initialSelectedCatIds shouldn't be null here since it was set on build, but we check just in case.
    if (categoryVal.isEmpty &&
        currentCatIds == (_initialSelectedCatIds ?? "")) {
      Fluttertoast.showToast(
          msg: "Please select the Wishlist Name or enter New Wishlist Name",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black.withValues(alpha: 0.8),
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    // Calculate expected favorite status based on selection
    bool hasSelected =
        provider.wishlistCategories?.any((c) => c?.isSelected == true) ?? false;
    bool hasNew = categoryVal.isNotEmpty;
    bool isFav = hasSelected || hasNew;

    final success = await provider.submitWishlistUpdate(
      widget.product.productId!,
      categoryVal,
    );

    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context, isFav); // Close Category Selection Dialog
      _showSuccessDialog(
          context, provider.actionError ?? "Wishlist Updated Successfully");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.actionError ?? "Failed to update wishlist")));
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          // Auto-dismiss logic
          Future.delayed(const Duration(seconds: 2), () {
            if (ctx.mounted) Navigator.of(ctx).pop();
          });

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r)),
            child: Container(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, size: 24.sp, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryButtonColor,
                      padding: EdgeInsets.symmetric(
                          horizontal: 30.w, vertical: 10.h),
                    ),
                    child: Text("Close",
                        style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                  )
                ],
              ),
            ),
          );
        });
  }
}

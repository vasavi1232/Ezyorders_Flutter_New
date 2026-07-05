import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';

import '../../../../core/utils/common_methods.dart';
import '../../../providers/product_list_provider.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductListProvider>(context);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    "Filter by",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        "assets/images/closeicon.png",
                        width: 20.w,
                        height: 20.w,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories (Divisions)
                    // Categories Section (Unified Divisions/Groups/Sub-groups)
                    if (provider.divisionslist.isNotEmpty ||
                        provider.groupslist.isNotEmpty ||
                        provider.subGroupslist.isNotEmpty) ...[
                      _buildSectionHeader("Categories"),

                      // Divisions (Primary Categories)
                      if (provider.divisionslist.isNotEmpty) ...[
                        _buildDivisionList(provider),
                        SizedBox(height: 15.h),
                      ],

                      // Groups (Sub-categories level 1)
                      if (provider.groupslist.isNotEmpty) ...[
                        if (provider.divisionName.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              CommonMethods.decodeHtmlEntities(provider.divisionName),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        _buildGroupList(provider),
                        SizedBox(height: 15.h),
                      ],

                      // Sub-groups (Sub-categories level 2 - e.g. "Bars Medium")
                      if (provider.subGroupslist.isNotEmpty) ...[
                        // Division Name (e.g. Confectionery)
                        if (provider.divisionName.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              CommonMethods.decodeHtmlEntities(provider.divisionName),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        // Group Name (e.g. Chocolate)
                        if (provider.groupName.isNotEmpty &&
                            provider.groupName != provider.divisionName)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              CommonMethods.decodeHtmlEntities(provider.groupName),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        _buildSubGroupList(provider),
                        SizedBox(height: 15.h),
                      ],
                    ],


                    // Suppliers — updates live when a category is toggled
                    if (provider.supplierslist.isNotEmpty ||
                        provider.isFilterRefreshing) ...[
                      _buildSectionHeader("Suppliers"),
                      if (provider.isFilterRefreshing)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Center(
                            child: SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor),
                              ),
                            ),
                          ),
                        )
                      else
                        _buildSupplierList(provider),
                      SizedBox(height: 15.h),
                    ],

                    // Tags
                    if (provider.tagslist.isNotEmpty) ...[
                      _buildSectionHeader("Tags"),
                      SizedBox(height: 6.h),
                      _buildTagGrid(provider),
                      SizedBox(height: 15.h),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: ElevatedButton(
                      onPressed: () {
                        provider.onFilterSubmit();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                      child: Text(
                        "Apply Filter",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: () {
                        provider.onFilterClear();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        backgroundColor: Colors.grey[100],
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                      child: Text(
                        "Clear",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.primaryColor,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDivisionList(ProductListProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.divisionslist.length,
      itemBuilder: (context, index) {
        final item = provider.divisionslist[index];
        final isSelected = item.selected == "Yes";
        final countStr =
            item.products != null && item.products.toString().isNotEmpty
                ? " (${item.products})"
                : "";
        return _buildFilterItem(
            CommonMethods.decodeHtmlEntities("${item.groupLevel1 ?? ""}$countStr"),
          isSelected,
          () => provider.toggleDivisionSelection(index),
        );
      },
    );
  }

  Widget _buildGroupList(ProductListProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.groupslist.length,
      itemBuilder: (context, index) {
        final item = provider.groupslist[index];
        final isSelected = item.groupSelected == "Yes";
        final countStr =
            item.products != null && item.products.toString().isNotEmpty
                ? " (${item.products})"
                : "";
        return _buildFilterItem(
          CommonMethods.decodeHtmlEntities("${item.groupLevel2 ?? ""}$countStr"),
          isSelected,
          () => provider.toggleGroupSelection(index),
        );
      },
    );
  }

  Widget _buildSupplierList(ProductListProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.supplierslist.length,
      itemBuilder: (context, index) {
        final item = provider.supplierslist[index];
        final isSelected = item.selected == "Yes";
        final countStr =
            item.products != null && item.products.toString().isNotEmpty
                ? " (${item.products})"
                : "";
        return _buildFilterItem(
            CommonMethods.decodeHtmlEntities("${item.brandName ?? ""}$countStr"),
          isSelected,
          () => provider.toggleSupplierSelection(index),
        );
      },
    );
  }

  Widget _buildTagGrid(ProductListProvider provider) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: List.generate(provider.tagslist.length, (index) {
        final item = provider.tagslist[index];
        final isSelected = item.tagSelected == "Yes";
        return InkWell(
          onTap: () => provider.toggleTagSelection(index),
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.grey[400]!),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
        CommonMethods.decodeHtmlEntities(item.tagName ?? ""),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }


  Widget _buildSubGroupList(ProductListProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.subGroupslist.length,
      itemBuilder: (context, index) {
        final item = provider.subGroupslist[index];
        final isSelected = item.groupSelected == "Yes";
        final countStr =
            item.products != null && item.products.toString().isNotEmpty
                ? " (${item.products})"
                : "";
        return _buildFilterItem(
          CommonMethods.decodeHtmlEntities("${item.groupLevel3 ?? ""}$countStr"),
          isSelected,
          () => provider.toggleSubGroupSelection(index),
        );
      },
    );
  }

  Widget _buildFilterItem(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Image.asset(
              isSelected
                  ? "assets/images/checked.png"
                  : "assets/images/unchecked.png",
              width: 18.w,
              height: 18.w,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

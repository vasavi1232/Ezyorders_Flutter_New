import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../data/models/delivery_location_response.dart';

class DeliveryLocationDialog extends StatefulWidget {
  final List<DeliveryLocationResult> deliveryLocations;
  final String? selectedDeliveryLocationId;
  final Function(String locationId, String charge) onLocationSelected;

  const DeliveryLocationDialog({
    super.key,
    required this.deliveryLocations,
    required this.selectedDeliveryLocationId,
    required this.onLocationSelected,
  });

  @override
  State<DeliveryLocationDialog> createState() => _DeliveryLocationDialogState();
}

class _DeliveryLocationDialogState extends State<DeliveryLocationDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<DeliveryLocationResult> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _filteredLocations = widget.deliveryLocations;
  }

  void _filterLocations(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredLocations = widget.deliveryLocations;
      });
    } else {
      final lowercaseQuery = query.toLowerCase();
      setState(() {
        _filteredLocations = widget.deliveryLocations.where((location) {
          final locName = location.locationName?.toLowerCase() ?? "";
          final subLocName = location.subLocationName?.toLowerCase() ?? "";
          return locName.contains(lowercaseQuery) || subLocName.contains(lowercaseQuery);
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        // Provide a stable max height
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Choose Delivery Location",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey, size: 24.w),
                ),
              ],
            ),
            SizedBox(height: 15.h),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _filterLocations,
              decoration: InputDecoration(
                hintText: "Search location...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 15.h),

            // List of Locations
            Flexible(
              child: _filteredLocations.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Text(
                          "No Delivery Locations found",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filteredLocations.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final location = _filteredLocations[index];
                          String displayText = location.locationName ?? "";
                          if (location.subLocationName != null && location.subLocationName!.isNotEmpty) {
                            displayText += " - ${location.subLocationName}";
                          }
                          final isSelected = location.deliveryLocationId == widget.selectedDeliveryLocationId;

                          return InkWell(
                            onTap: () {
                              if (location.deliveryLocationId != null) {
                                widget.onLocationSelected(
                                  location.deliveryLocationId!,
                                  location.deliveryLocationCharge ?? "0"
                                );
                              }
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 5.w),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? AppTheme.primaryColor : Colors.grey,
                                    size: 20.w,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      displayText,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

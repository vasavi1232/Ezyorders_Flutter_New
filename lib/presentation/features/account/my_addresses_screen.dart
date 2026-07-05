import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../../data/models/profile_models.dart';
import '../../../core/constants/app_theme.dart';
import '../../../config/routes/app_routes.dart';
import '../../widgets/custom_loader_widget.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AddressProvider>().fetchAddresses();
      }
    });
  }

  void _confirmDelete(String addressId) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Delete Address"),
              content:
                  const Text("Are you sure you want to delete this address?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("Cancel",
                        style: TextStyle(
                            color: AppTheme.secondaryButtonColor,
                            fontWeight: FontWeight.bold))),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context
                        .read<AddressProvider>()
                        .deleteAddress(addressId)
                        .then((success) {
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Address deleted successfully")));
                      }
                    });
                  },
                  child: Text("Delete",
                      style: TextStyle(
                          color: AppTheme.primaryButtonColor,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Address List",
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          InkWell(
            onTap: () {
              context.push(AppRoutes.addAddress);
            },
            child: Padding(
              padding: EdgeInsets.only(right: 12.w, top: 8.h, bottom: 8.h),
              child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppTheme.secondaryButtonColor,
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(20.r)),
                  child: Text(
                    'Add',
                    style: TextStyle(
                        color: Colors.white, 
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900),
                  )),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<AddressProvider>(
            builder: (context, provider, child) {
              // Moved isLoading check to Overlay

              if (provider.addressList.isEmpty && !provider.isLoading) {
                return Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off,
                        size: 60.sp, color: AppTheme.primaryColor),
                    SizedBox(height: 10.h),
                    Text("No addresses found",
                        style: TextStyle(
                            fontSize: 16.sp, color: AppTheme.darkGrayColor)),
                    SizedBox(height: 20.h),
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.addAddress),
                      icon: const Icon(Icons.add, color: AppTheme.white),
                      label: const Text("Add New Address",
                          style: TextStyle(color: AppTheme.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor),
                    )
                  ],
                ));
              }

              return ListView.builder(
                  padding: EdgeInsets.all(12.w),
                  itemCount: provider.addressList.length,
                  itemBuilder: (ctx, index) {
                    final address = provider.addressList[index];
                    return _buildAddressItem(address);
                  });
            },
          ),
          Consumer<AddressProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
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

  Widget _buildAddressItem(AddressItem address) {
    final bool isDefault = address.defaultAddress == "Yes";

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW (Name + Edit Icon)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "${address.firstName ?? ""} ${address.lastName ?? ""}",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              /// Edit Icon
              InkWell(
                onTap: () {
                  context.push(AppRoutes.addAddress, extra: address);
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          //SizedBox(height: 6.h),

          /// Address Line (single paragraph like screenshot)
          Text(
            "${address.street ?? ""}"
            "${address.street2 != null && address.street2!.isNotEmpty ? ", ${address.street2}" : ""}, "
            "${address.suburb ?? ""}, ${address.state ?? ""}, ${address.postcode ?? ""}",
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
          ),

          SizedBox(height: 18.h),

          /// Mobile
          Text(
            "Mobile : ${address.phone ?? ""}",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black
            ),
          ),

          /// Default Billing & Shipping Row + Delete Icon
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: isDefault
                      ? null
                      : () {
                          context
                              .read<AddressProvider>()
                              .setDefaultAddress(address)
                              .then((success) {
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Default address updated")));
                            }
                          });
                        },
                  child: Row(
                    children: [
                      /// Radio indicator
                      Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDefault ? AppTheme.tealColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isDefault
                            ? Center(
                                child: Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.tealColor,
                                  ),
                                ),
                              )
                            : null,
                      ),

                      SizedBox(width: 8.w),

                      Expanded(
                        child: Text(
                          "Default Billing and Shipping",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDefault
                                ? AppTheme.primaryColor
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Delete Icon
              InkWell(
                onTap: () => _confirmDelete(address.addressId ?? ""),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

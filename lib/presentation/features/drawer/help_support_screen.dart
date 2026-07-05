import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/custom_loader_widget.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

import '../../../config/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openMap(String address) async {
    // Basic Google Maps intent
    final Uri launchUri =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$address");
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Help & Support",
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
              final profile =
                  provider.profileResponse?.results?.isNotEmpty == true
                      ? provider.profileResponse!.results![0]
                      : null;

              if (profile == null) {
                return const SizedBox.shrink(); // Overlay handles it
              }

              final mobile = profile.companyMobile ?? "N/A";
              final email = profile.companyEmail ?? "N/A";
              final address =
                  "${profile.companyStreet}, ${profile.companySuburb}, ${profile.companyState}, ${profile.companyPostcode}";
              // Construct address matching Android logic

              return Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactItem(
                      icon: Icons.phone,
                      title: "Mobile Number",
                      value: mobile,
                      onTap: () => _makePhoneCall(mobile),
                    ),
                    _buildDivider(),
                    _buildContactItem(
                      icon: Icons.email,
                      title: "Email Address",
                      value: email,
                      onTap: () => _sendEmail(email),
                    ),
                    _buildDivider(),
                    _buildContactItem(
                      icon: Icons.location_on,
                      title: "Address",
                      value: address,
                      onTap: () => _openMap(address),
                    ),
                  ],
                ),
              );
            },
          ),
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              final profile =
                  provider.profileResponse?.results?.isNotEmpty == true
                      ? provider.profileResponse!.results![0]
                      : null;

              if (profile == null) {
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

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Divider(color: AppTheme.lightGrayBg),
    );
  }

  Widget _buildContactItem(
      {required IconData icon,
      required String title,
      required String value,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppTheme.lightGrayBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.tealColor, size: 24.sp),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.darkGrayColor,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14.sp, color: AppTheme.darkGrayColor),
          ],
        ),
      ),
    );
  }
}

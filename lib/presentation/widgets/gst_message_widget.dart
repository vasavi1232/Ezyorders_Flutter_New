import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';

class GstMessageWidget extends StatelessWidget {
  final EdgeInsetsGeometry? padding;

  GstMessageWidget({super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final results = provider.profileResponse?.results;
        final profile = (results != null && results.isNotEmpty) ? results[0] : null;

        if (profile == null) return const SizedBox.shrink();

        final showGst = profile.showPriceIncludingGst;
        String? message;

        if (showGst == 'Yes') {
          message = profile.priceIncludesGstMessage;
        } else if (showGst == 'No') {
          message = profile.priceExcludesGstMessage;
        }

        if (message == null || message.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

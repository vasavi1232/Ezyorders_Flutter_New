import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/common_methods.dart';
import '../../../providers/dashboard_provider.dart';

class CloseAccountDialog extends StatefulWidget {
  final String htmlMessage;

  const CloseAccountDialog({Key? key, required this.htmlMessage}) : super(key: key);

  @override
  _CloseAccountDialogState createState() => _CloseAccountDialogState();
}

class _CloseAccountDialogState extends State<CloseAccountDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      setState(() {});
    });
  }

  void _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorMessage = "Please Enter Reason";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final provider = context.read<DashboardProvider>();
    final response = await provider.closeAccount(reason);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response['status'] == 200) {
      setState(() {
        _isSuccess = true;
      });
      
      // Store references needed for delayed execution
      final dashboardProvider = context.read<DashboardProvider>();
      final goRouter = GoRouter.of(context);
      final nav = Navigator.of(context);

      Future.delayed(const Duration(seconds: 5), () async {
        if (nav.mounted) {
          nav.pop(); // Close the dialog
        }
        await dashboardProvider.logout();
        goRouter.go(AppRoutes.login);
      });
    } else {
      Fluttertoast.showToast(msg: response['message'] ?? "Failed to close account");
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isSuccess,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isSuccess ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Account Closed", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 10.h),
        Text("Your account has been successfully closed.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Html(data: CommonMethods.decodeHtmlEntities(widget.htmlMessage, stripTags: false), style: {
          "body": Style(
            textAlign: TextAlign.center,
            fontSize: FontSize(14.sp),
          ),
          "strong": Style(
            fontWeight: FontWeight.bold,
          ),
        }),
        SizedBox(height: 10.h),
        RichText(
          text: TextSpan(
            text: "Account Close Reason ",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14.sp),
            children: [
              TextSpan(text: "*", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        TextField(
          controller: _reasonController,
          maxLines: 4,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: "Please Enter Reason",
            hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
          ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryButtonColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _reasonController.text.trim().isNotEmpty ? Colors.red.shade700 : Color(0xFFE28B9B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading 
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ),
            ),
          ],
        )
      ],
    );
  }
}

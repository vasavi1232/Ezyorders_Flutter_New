import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_messages.dart';
import '../../widgets/custom_loader_widget.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Visibility toggles
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final provider = context.read<DashboardProvider>();
    final oldPw = _oldPasswordController.text.trim();
    final newPw = _newPasswordController.text.trim();
    final confirmPw = _confirmPasswordController.text.trim();

    // Validation Logic matching Android (ChangePasswordActivity.kt)
    // 1. Check Empty
    if (oldPw.isEmpty) {
      _showError(AppMessages.pleaseEnterCurrentPassword);
      return;
    }

    if (newPw.isEmpty) {
      _showError(AppMessages.pleaseEnterNewPassword);
      return;
    }

    if (confirmPw.isEmpty) {
      _showError(AppMessages.pleaseConfirmNewPassword);
      return;
    }

    if (newPw != confirmPw) {
      _showError(AppMessages.pswdNotMatching);
      return;
    }

    if (oldPw == newPw) {
      _showError(AppMessages.newPswdCannotBeSame);
      return;
    }

    // Call API
    bool success = await provider.changePassword(oldPw, newPw);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppMessages.pswdUpdatedSuccessfully)),
      );
      context.pop(); // Go back
    } else {
      _showError(provider.actionError ?? "An error occurred");
    }
  }

  void _showError(String message) {
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = AppTheme.isTablet(context);
    final bool isTabletLandscape = MediaQuery.of(context).orientation == Orientation.landscape && isTablet;
    final double buttonHeight = isTabletLandscape ? 75.h : 50.h;

    // Replicating Layout from Android XML likely (Simple form)
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Change Password",
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
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    // Old Password
                    _buildLabel("Current Password *"),
                    _buildPasswordField(
                        _oldPasswordController,
                        AppMessages.enterYourCurrentPassword,
                        _oldPasswordVisible, (val) {
                      setState(() => _oldPasswordVisible = val);
                    }),
                    SizedBox(height: 20.h),

                    // New Password
                    _buildLabel("New Password *"),
                    _buildPasswordField(
                        _newPasswordController,
                        AppMessages.enterYourNewPassword,
                        _newPasswordVisible, (val) {
                      setState(() => _newPasswordVisible = val);
                    }),
                    SizedBox(height: 20.h),

                    // Confirm Password
                    _buildLabel("Confirm Password * "),
                    _buildPasswordField(
                        _confirmPasswordController,
                        AppMessages.enterYourConfirmPassword,
                        _confirmPasswordVisible, (val) {
                      setState(() => _confirmPasswordVisible = val);
                    }),
                    SizedBox(height: 40.h),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryButtonColor,
                          minimumSize: Size(double.infinity, isTabletLandscape ? 75.h : 45.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.authButtonRadius.r)),
                        ),
                        child: Text("Save",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.isLoading)
                Container(
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
                )
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text,
          style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller,
      String hintText,
      bool isVisible,
      Function(bool) onToggle) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppTheme.hintColor,
          fontSize: 14.sp,
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.inputRadius.r),
            borderSide: BorderSide(color: AppTheme.borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.inputRadius.r),
            borderSide: BorderSide(color: AppTheme.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.inputRadius.r),
            borderSide: const BorderSide(color: AppTheme.primaryColor)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.hintColor),
          onPressed: () => onToggle(!isVisible),
        ),
      ),
    );
  }
}

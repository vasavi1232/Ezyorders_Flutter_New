import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/service_locator.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/constants/storage_keys.dart';
import '../../config/routes/app_routes.dart';
import '../../core/utils/common_methods.dart';

import '../../core/constants/app_messages.dart';
import '../../core/constants/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignUpProvider extends ChangeNotifier {
  final AuthRepository _repository = getIt<AuthRepository>();

  // Text Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController orderEmailsController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  
  // Focus Nodes for standard field focusing logic
  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode orderEmailsFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  // State
  bool _isLoading = false;
  String? _errorMsg;
  String? _titleVal;
  String _emailRequired = "No"; // Default from Android init

  // Options
  final List<String> titleOptions = [
    "Select Title",
    "Mr",
    "Ms.",
    "Mrs",
    "Miss"
  ];

  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  String? get titleVal => _titleVal;
  String get emailRequired => _emailRequired;

  SignUpProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _emailRequired = prefs.getString(StorageKeys.emailRequired) ?? "No";
    notifyListeners();
  }

  void setTitle(String? value) {
    if (value != "Select Title") {
      _titleVal = value;
    } else {
      _titleVal = null;
    }
    notifyListeners();
  }

  Future<void> submitSignUp(BuildContext context) async {
    _errorMsg = null;

    // Validation matching Android saveEventClick
    if (_titleVal == null || _titleVal!.isEmpty) {
      _showErrorDialog(context, AppMessages.pleaseSelectTitle);
      return;
    }
    if (firstNameController.text.trim().isEmpty) {
      _showErrorDialog(context, AppMessages.pleaseEnterFirstName);
      firstNameFocus.requestFocus();
      return;
    }
    if (lastNameController.text.trim().isEmpty) {
      _showErrorDialog(context, AppMessages.pleaseEnterLastName);
      lastNameFocus.requestFocus();
      return;
    }
    if (mobileController.text.trim().isEmpty) {
      _showErrorDialog(context, AppMessages.pleaseEnterMobileNumber);
      mobileFocus.requestFocus();
      return;
    }

    // Email Validation Logic (Case-insensitive setting check)
    final email = emailController.text.trim();
    final bool isEmailMandatory = _emailRequired.toLowerCase() == "yes";

    if (!isEmailMandatory) {
      if (email.isNotEmpty && !_isValidEmail(email)) {
        _showErrorDialog(context, AppMessages.pleaseEnterValidEmail);
        emailFocus.requestFocus();
        return;
      }
    } else {
      if (email.isEmpty) {
        _showErrorDialog(context, AppMessages.pleaseEnterEmail);
        emailFocus.requestFocus();
        return;
      }
      if (!_isValidEmail(email)) {
        _showErrorDialog(context, AppMessages.pleaseEnterValidEmail);
        emailFocus.requestFocus();
        return;
      }
    }

    // Order Emails Validation
    final orderEmails = orderEmailsController.text.trim();
    if (orderEmails.isNotEmpty) {
      final emails = orderEmails.split(',').map((e) => e.trim()).toList();
      for (var e in emails) {
        if (e.isNotEmpty && !_isValidEmail(e)) {
          _showErrorDialog(context, AppMessages.enterValidOrderEmail);
          orderEmailsFocus.requestFocus();
          return;
        }
      }
    }

    // Password Validation
    final pass = passwordController.text;
    final confPass = confirmPasswordController.text;

    if (pass.isEmpty) {
      _showErrorDialog(context, AppMessages.enterYourPassword);
      passwordFocus.requestFocus();
      return;
    }
    if (confPass.isEmpty) {
      _showErrorDialog(context, AppMessages.pleaseConfirmNewPassword);
      confirmPasswordFocus.requestFocus();
      return;
    }
    if (pass != confPass) {
      _showErrorDialog(context, AppMessages.pswdNotMatching);
      confirmPasswordFocus.requestFocus();
      return;
    }

    // Proceed to API Call
    _isLoading = true;
    notifyListeners();

    try {
      final deviceType = await CommonMethods.getDeviceType();
      final result = await _repository.signUp(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phone: mobileController.text.trim(),
        email: email,
        password: pass,
        receiptEmails: orderEmails,
        title: _titleVal!,
        deviceType: deviceType,
      );

      _isLoading = false;
      notifyListeners();

      if (result is UserEntity && result.status != 200 && result.status != null) {
        if (context.mounted) {
          _showErrorDialog(context, result.error ?? result.message ?? AppMessages.failureMsg);
        }
        return;
      }

      if (context.mounted) {
        _showSuccessDialog(context);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ SignUp Error: $e');
      debugPrint('Stack Trace:\n$stackTrace');
      _isLoading = false;
      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
      notifyListeners();
    }
  }

  void _setError(String msg) {
    _errorMsg = msg;
    notifyListeners();
  }

  void clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    mobileController.clear();
    emailController.clear();
    orderEmailsController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _titleVal = null;
    _errorMsg = null;
    _isLoading = false;
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    // Platform-standard robust email regex
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryButtonColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Registration Confirmation",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      clearForm();
                    },
                    child: Icon(Icons.close, color: Colors.white, size: 22.sp),
                  ),
                ],
              ),
            ),
            // Body
            Container(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppTheme.successGreen, width: 4.w),
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppTheme.successGreen,
                      size: 50.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Congratulations!!!",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "Your account has been successfully registered.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        clearForm();
                        context.go(AppRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 2,
                      ),
                      child: Text(
                        "Click here to Login",
                        style: TextStyle(
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

  void _showErrorDialog(BuildContext context, String error) {
    CommonMethods.showErrorPopup(
      context,
      title: "Registration Failed",
      subTitle: "Sign Up Failed",
      message: error,
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    orderEmailsController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    // Dispose Focus Nodes
    firstNameFocus.dispose();
    lastNameFocus.dispose();
    mobileFocus.dispose();
    emailFocus.dispose();
    orderEmailsFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }
}

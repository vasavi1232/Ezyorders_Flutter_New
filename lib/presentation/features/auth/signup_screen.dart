import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/signup_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../config/routes/app_routes.dart';
import '../../../core/constants/app_messages.dart';
import '../../widgets/custom_loader_widget.dart';

import 'package:flutter/services.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          Future.microtask(() {
            if (context.mounted) {
              context.read<SignUpProvider>().clearForm();
            }
          });
        }
      },
      child: Scaffold(
      backgroundColor: AppTheme.primaryColor, // @color/blue
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.primaryColor,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: Colors.white,
                            child: Column(
                              children: [
                                // Header Card
                                Card(
                                  margin: EdgeInsets.symmetric(vertical: 3), // @dimen/dimens_5dp
                                  elevation: 5,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  child: Container(
                                    height: 55, // @dimen/dimen_55
                                    padding: EdgeInsets.symmetric(horizontal: 15),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                          GestureDetector(
                                            onTap: () {
                                              if (context.mounted) {
                                                context.read<SignUpProvider>().clearForm();
                                                context.go('/login');
                                              }
                                            },
                                            child: Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: AppTheme.backIconSize(context)),
                                          ),
                                        Expanded(
                                          child: Text(
                                            AppMessages.signUp, // @string/sign_up
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black, // @color/text_color
                                              fontSize: 18, // @dimen/_18sdp
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 45), // Balance spacing @dimen/dimen_45
                                      ],
                                    ),
                                  ),
                                ),

                                // Form Content
                                Expanded(
                                  child: Container(
                                    color: Colors.white,
                                      child: SingleChildScrollView(
                                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                        padding: EdgeInsets.all(15), // @dimen/dimen_15
                                        child: Consumer<SignUpProvider>(
                                          builder: (context, provider, child) {
                                            return GestureDetector(
                                              onTap: () => FocusScope.of(context).unfocus(),
                                              behavior: HitTestBehavior.opaque,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Title
                                              _buildLabel(AppMessages.titleMsg), // @string/title_
                                              SizedBox(height: 5),
                                              Container(
                                                height: 45,
                                                padding: EdgeInsets.symmetric(horizontal: 10),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: AppTheme.borderColor),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: DropdownButtonHideUnderline(
                                                  child: Theme(
                                                    data: Theme.of(context).copyWith(
                                                      colorScheme: Theme.of(context).colorScheme.copyWith(
                                                        primaryContainer: Colors.white,
                                                        secondaryContainer: Colors.white,
                                                      ),
                                                      focusColor: Colors.transparent,
                                                      hoverColor: Colors.transparent,
                                                      splashColor: Colors.transparent,
                                                      highlightColor: Colors.transparent,
                                                    ),
                                                    child: DropdownButton<String>(
                                                      dropdownColor: Colors.white,
                                                      isExpanded: true,
                                                      value: provider.titleVal ?? "Select Title",
                                                      icon: const Icon(Icons.arrow_drop_down),
                                                      items: provider.titleOptions.map((String value) {
                                                        return DropdownMenuItem<String>(
                                                          value: value,
                                                          child: Text(value, style: TextStyle(fontSize: 14)),
                                                        );
                                                      }).toList(),
                                                      onChanged: (newValue) {
                                                        provider.setTitle(newValue);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              SizedBox(height: 10),

                                              // First Name
                                              _buildLabel(AppMessages.firstName), // @string/first_name
                                              _buildTextField(provider.firstNameController, AppMessages.firstNameHint, TextInputType.name, focusNode: provider.firstNameFocus, isName: true),

                                              SizedBox(height: 10),

                                              // Last Name
                                              _buildLabel(AppMessages.lastName), // @string/last_name_
                                              _buildTextField(provider.lastNameController, AppMessages.lastNameHint, TextInputType.name, focusNode: provider.lastNameFocus, isName: true),

                                              SizedBox(height: 10),

                                              // Mobile
                                              _buildLabel(AppMessages.mobileNumber), // @string/mobile_number
                                              _buildTextField(provider.mobileController, AppMessages.mobileHint, TextInputType.phone, focusNode: provider.mobileFocus, isPhone: true),

                                              SizedBox(height: 10),

                                              // Email
                                              _buildLabel("${AppMessages.email}${provider.emailRequired.toLowerCase() == "yes" ? " *" : ""}"),
                                              _buildTextField(provider.emailController, AppMessages.emailHint, TextInputType.emailAddress, focusNode: provider.emailFocus),

                                              SizedBox(height: 10),

                                              // Order Emails
                                              _buildLabel(AppMessages.orderReceiptEmails),
                                              _buildTextField(provider.orderEmailsController, AppMessages.orderEmailsHint, TextInputType.emailAddress, focusNode: provider.orderEmailsFocus),

                                              SizedBox(height: 5),
                                              Text(
                                                "Note : Please add Email(s) in comma separated", // @string/note
                                                style: TextStyle(
                                                  color: AppTheme.redColor,
                                                  fontSize: 12,
                                                ),
                                              ),

                                              SizedBox(height: 10),

                                              // Password
                                              _buildLabel(AppMessages.password), // @string/password_m
                                              _buildTextField(provider.passwordController, AppMessages.passwordHint, TextInputType.visiblePassword, isPassword: true, focusNode: provider.passwordFocus),

                                              SizedBox(height: 10),

                                              // Confirm Password
                                              _buildLabel("Confirm Password *"), // @string/cnfpassword_m
                                              _buildTextField(provider.confirmPasswordController, "Enter Your Password Again", TextInputType.visiblePassword, isPassword: true, focusNode: provider.confirmPasswordFocus, textInputAction: TextInputAction.done),

                                              SizedBox(height: 30),

                                              // Submit Button
                                              SizedBox(
                                                width: double.infinity,
                                                height: 45, // @dimen/dimen_45
                                                child: ElevatedButton(
                                                  onPressed: provider.isLoading ? null : () {
                                                    provider.submitSignUp(context);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.primaryButtonColor, // @color/tealcolor
                                                    minimumSize: Size(double.infinity, 45.h),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.authButtonRadius)),
                                                  ),
                                                  child: Text(
                                                    "Submit", // @string/submit
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              SizedBox(height: 10),

                                              // Login Link
                                              Center(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    if (context.mounted) {
                                                      context.read<SignUpProvider>().clearForm();
                                                      context.go(AppRoutes.login);
                                                    }
                                                  },
                                                  child: RichText(
                                                    text: TextSpan(
                                                      text: "Already have an account? ",
                                                      style: TextStyle(
                                                        color: AppTheme.blackColor, // Match screenshot text color
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: 'Roboto',
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: "Login",
                                                          style: TextStyle(
                                                            color: AppTheme.primaryButtonColor, // Orange/Gold
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              SizedBox(height: 20),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Loading Overlay
            // Loading Overlay
            Consumer<SignUpProvider>(
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
      ),
    ),
  );
}

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 3), // @dimen/dimen_3
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.primaryColor, // @color/blue
          fontSize: 14, // @dimen/_14sdp
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType inputType, {bool isPassword = false, FocusNode? focusNode, bool isName = false, bool isPhone = false, TextInputAction textInputAction = TextInputAction.next}) {
    return Container(
      margin: EdgeInsets.only(top: 5), // @dimen/dimens_5
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        keyboardType: inputType,
        textInputAction: textInputAction,
        inputFormatters: [
          if (isName) FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
          if (isPhone) FilteringTextInputFormatter.digitsOnly,
        ],
        style: TextStyle(
          color: AppTheme.textColor,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.hintColor, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFFFFFFF), // White background
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),

          // Black rectangular border
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.inputRadius.r),
            borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.inputRadius.r),
            borderSide: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.inputRadius.r),
            borderSide: BorderSide(color: AppTheme.borderColor, width: 2),
          ),
        ),
      ),
    );
  }
}

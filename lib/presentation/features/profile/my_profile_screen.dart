import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/constants/url_api_key.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/common_methods.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/custom_loader_widget.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _streetController;
  late TextEditingController _street2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _postcodeController;

  final ImagePicker _picker = ImagePicker();
  bool _isEmailRequired = true;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final emailReq = prefs.getString(StorageKeys.emailRequired) ?? "No";
    if (mounted) {
      setState(() {
        _isEmailRequired = emailReq.toLowerCase() == "yes";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    final provider = context.read<DashboardProvider>();
    final profile = provider.profileResponse?.results?[0];

    _firstNameController =
        TextEditingController(text: profile?.firstName ?? "");
    _lastNameController = TextEditingController(text: profile?.lastName ?? "");
    _streetController = TextEditingController(text: profile?.street ?? "");
    _street2Controller = TextEditingController(text: profile?.street2 ?? "");
    _cityController = TextEditingController(
        text: profile?.suburb ??
            ""); // Mapping suburb to city/town as per XML hint "Town / City"
    _stateController = TextEditingController(
        text: profile?.state ?? ""); // XML says "State / Country"
    _emailController = TextEditingController(text: profile?.email ?? "");
    _mobileController = TextEditingController(text: profile?.phone ?? profile?.mobile ?? "");
    _postcodeController = TextEditingController(
        text: profile?.postcode ??
            ""); // XML doesn't explicitly show postcode field but model has it. Will keep it separate or merged?
    // Looking at XML:
    // firstName, lastName, street1, street2, city, state, email, mobile.
    // Postcode is NOT in the XML provided in context?
    // Let's re-read XML.
    // XML has: prfFirstNameEdt, prfLastNameEdt, street1Edt, street2Edt, cityEdt, stateEdt, prfEmailEdt, prfModileEdt.
    // No postcode field in XML.
    // But updateProfile API usually requires it.
    // I will pass the existing postcode from model if not editable, or add it if needed.
    // Android XML usually is the source of truth for UI. If not there, maybe it's merged?
    // I'll keep it as a value but maybe hidden if not in UI.
    // Wait, createOrder requires postcode. editProfile requires postcode.
    // If user can't edit it, I should just pass the old one.
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetController.dispose();
    _street2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        _cropImage(image.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: AppTheme.primaryColor),
                  title: Text('Photo Gallery',
                      style: TextStyle(
                          fontSize: 16.sp,
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt,
                      color: AppTheme.primaryColor),
                  title: Text('Camera',
                      style: TextStyle(
                          fontSize: 16.sp,
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cropImage(String sourcePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: AppTheme.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );

      if (croppedFile != null) {
        // Upload
        if (!mounted) return;
        final success = await context
            .read<DashboardProvider>()
            .updateProfileImage(File(croppedFile.path));
        if (success && mounted) {
          await CommonMethods.showSuccessPopup(
            context,
            title: "Success",
            subTitle: "Success",
            message: "Profile image updated",
            autoCloseDuration: 3,
          );
        } else if (!success && mounted) {
          final msg = context.read<DashboardProvider>().actionError ??
              "Failed to update image";
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      debugPrint("Error cropping image: $e");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation Logic from Android?
    // "Enter valid first name" if empty
    // "Enter valid last name" if empty
    // "Enter valid street address" if empty
    // "Enter valid town / city" if empty
    // "Enter valid state / country" if empty

    final provider = context.read<DashboardProvider>();

    final success = await provider.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        street: _streetController.text,
        street2: _street2Controller.text,
        suburb: _cityController.text,
        state: _stateController.text,
        postcode: _postcodeController.text);

    if (success) {
      if (mounted) {
        await CommonMethods.showSuccessPopup(
          context,
          title: "Success",
          subTitle: "Success",
          message: "Profile updated successfully",
          autoCloseDuration: 3,
        );
        if (mounted) context.pop();
      }
    } else if (!success && mounted) {
      final msg = provider.actionError ?? AppMessages.failureMsg;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = AppTheme.isTablet(context);
    final bool isTabletLandscape = MediaQuery.of(context).orientation == Orientation.landscape && isTablet;

    return Scaffold(
      // backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 1,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0.r)),
              child: Container(
                height: 55.h,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back,
                          color: Colors.black, size: AppTheme.backIconSize(context)),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(right: 20.w),
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Content Card
            Expanded(
              child: Container(
                color: Colors.white,
                child: Card(
                  elevation: 5,
                  margin: EdgeInsets.all(15.w),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(15.w),
                    child: Stack(
                      children: [
                        Consumer<DashboardProvider>(
                          builder: (context, provider, child) {
                            // Moved isLoading check to Overlay

                            final profile =
                                provider.profileResponse?.results?.firstOrNull;
                            final userImage = profile?.image ?? "";
                            final imageUrl = (userImage.isNotEmpty &&
                                !userImage.contains("default"))
                                ? (userImage.startsWith("http")
                                ? userImage
                                : "${UrlApiKey.mainUrl}$userImage")
                                : "";

                            return Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          // Profile Image
                                          Center(
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                GestureDetector(
                                                  onTap: _showPickerOptions,
                                                  child: Container(
                                                    width: 100.w,
                                                    height: 100.w,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white,
                                                    ),
                                                    child: ClipOval(
                                                      child: imageUrl.isNotEmpty
                                                          ? CachedNetworkImage(
                                                        imageUrl:
                                                        imageUrl,
                                                        width: 100.w,
                                                        height: 100.w,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (context,
                                                            url) =>
                                                            Icon(
                                                              Icons.person,
                                                              size: 70.w,
                                                              color: AppTheme
                                                                  .primaryColor,
                                                            ),
                                                        errorWidget:
                                                            (context, url,
                                                            error) =>
                                                            Icon(
                                                              Icons.person,
                                                              size: 70.w,
                                                              color: AppTheme
                                                                  .primaryColor,
                                                            ),
                                                      )
                                                          : Icon(
                                                        Icons.person,
                                                        size: 70.w,
                                                        color: AppTheme
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: InkWell(
                                                    onTap: _showPickerOptions,
                                                    child: Container(
                                                      padding:
                                                      EdgeInsets.all(6.w),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                alpha: 0.1),
                                                            blurRadius: 4,
                                                            offset:
                                                            const Offset(
                                                                0, 2),
                                                          )
                                                        ],
                                                      ),
                                                      child: Icon(
                                                          Icons.camera_alt,
                                                          color: AppTheme
                                                              .primaryColor,
                                                          size: 20.sp),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 10.h),

                                          // First Name
                                          _buildLabel("First Name *"),
                                          _buildTextField(_firstNameController,
                                              "Enter First Name",
                                              validator: (v) => v!.isEmpty
                                                  ? AppMessages
                                                  .enterValidFirstName
                                                  : null),

                                          // Last Name
                                          _buildLabel("Last Name *"),
                                          _buildTextField(_lastNameController,
                                              "Enter Last Name",
                                              validator: (v) => v!.isEmpty
                                                  ? AppMessages
                                                  .enterValidLastName
                                                  : null),

                                          // Street Address
                                          _buildLabel("Street Address *"),
                                          _buildTextField(_streetController,
                                              "Enter Your House number and street name",
                                              validator: (v) => v!.isEmpty
                                                  ? AppMessages
                                                  .enterValidStreetAddress
                                                  : null),
                                          _buildTextField(_street2Controller,
                                              "Enter Your Apartment, suite, unit etc.."),

                                          // Town / City
                                          _buildLabel("Town / City *"),
                                          _buildTextField(_cityController,
                                              "Enter Your Town / City",
                                              validator: (v) => v!.isEmpty
                                                  ? AppMessages
                                                  .enterValidTownCity
                                                  : null),

                                          // State / Country
                                          _buildLabel("State / Country *"),
                                          _buildTextField(_stateController,
                                              "Enter Your State / Country",
                                              validator: (v) => v!.isEmpty
                                                  ? AppMessages
                                                  .enterValidStateCountry
                                                  : null),

                                          // Post Code
                                          _buildLabel("Post Code *"),
                                          _buildTextField(
                                            _postcodeController,
                                            "Enter Your Post Code",
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly
                                            ],
                                            validator: (v) => v!.isEmpty
                                                ? "Please enter valid post code"
                                                : null,
                                          ),

                                          // Email
                                          _buildLabel(_isEmailRequired ? "Email *" : "Email"),
                                          _buildTextField(
                                            _emailController,
                                            "",
                                            readOnly: false,
                                            keyboardType: TextInputType.emailAddress,
                                            validator: (v) {
                                              final email = v?.trim() ?? "";
                                              if (_isEmailRequired) {
                                                if (email.isEmpty) {
                                                  return AppMessages.pleaseEnterEmail;
                                                }
                                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                                  return AppMessages.pleaseEnterValidEmail;
                                                }
                                              } else {
                                                if (email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                                  return AppMessages.pleaseEnterValidEmail;
                                                }
                                              }
                                              return null;
                                            },
                                          ),

                                          // Mobile
                                          _buildLabel("Mobile Number *"),
                                          _buildTextField(
                                            _mobileController,
                                            "",
                                            readOnly: false,
                                            keyboardType: TextInputType.phone,
                                            validator: (v) => v!.isEmpty
                                                ? AppMessages.enterValidMobileNumber
                                                : null,
                                          ),

                                          SizedBox(height: 20.h),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Update Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: isTabletLandscape ? 75.h : 45.h,
                                    child: ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        AppTheme.primaryButtonColor,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(5.r)),
                                      ),
                                      child: Text("Update Details",
                                          style: TextStyle(
                                              fontSize: isTabletLandscape ? 16.sp : 14.sp,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                        Consumer<DashboardProvider>(
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
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 10.h, bottom: 5.h),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool readOnly = false,
        String? Function(String?)? validator,
        Color? textColor,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style:
        TextStyle(fontSize: 14.sp, color: textColor ?? AppTheme.textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.hintColor, fontSize: 14.sp),
          contentPadding:
          EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5.r),
            borderSide: BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5.r),
            borderSide: BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5.r),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }
}

import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;
import '../constants/app_theme.dart';
import '../../config/routes/app_router.dart';

class CommonMethods {
  static String productsBack = "";
  static String supplierIDs = "";
  static String categoryIDs = "";
  static String groupIDs = "";
  static String subGroupIDs = "";
  static String subSubGroupIDs = "";
  static String selecetedProducts = "";
  static String selectFirstTime = "";
  static String tagIDs = "";
  static String sortIDs = "";
  static String firstSuppliers = "";
  static String firstGroupids = "";
  static String firstSubGroupids = "";
  static String firstCatIds = "";
  static String firstSelProds = "";
  static String firstTags = "";
  static String filterSelected = "Show Products";

  // Shared pagination and state
  static String cartCount = "0";
  static int supplierCount = 0;
  static String suppliers = "";

  // Dynamic Price Formatting (Synced with Native Android CommonMethods.kt)
  static String priceCode = "\$";
  static int decimalDigits = 2;

  static String setPriceFormat(double? price) {
    if (price == null) return "$priceCode 0.${"0" * decimalDigits}";
    return "$priceCode ${price.toStringAsFixed(decimalDigits)}";
  }

  static String setPriceFormatString(String? price) {
    if (price == null || price.isEmpty || price == "null") {
      return "$priceCode 0.${"0" * decimalDigits}";
    }
    double? val = double.tryParse(price);
    if (val == null) return "$priceCode 0.${"0" * decimalDigits}";
    return "$priceCode ${val.toStringAsFixed(decimalDigits)}";
  }

  static void resetProductFilters() {
    productsBack = "";
    supplierIDs = "";
    categoryIDs = "";
    groupIDs = "";
    subGroupIDs = "";
    subSubGroupIDs = "";
    selecetedProducts = "";
    selectFirstTime = "";
    tagIDs = "";
    sortIDs = "";
    firstSuppliers = "";
    firstGroupids = "";
    firstSubGroupids = "";
    firstCatIds = "";
    firstSelProds = "";
    firstTags = "";
    filterSelected = "Show Products";
  }

  static String findDiscount(String? price, String? promoPrice) {
    if (price == null || promoPrice == null) return "0";

    // Strip everything except digits and dots
    String cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
    String cleanPromo = promoPrice.replaceAll(RegExp(r'[^0-9.]'), '');

    final priceVal = double.tryParse(cleanPrice) ?? 0.0;
    final promoVal = double.tryParse(cleanPromo) ?? 0.0;

    if (priceVal <= 0 || promoVal <= 0 || promoVal >= priceVal) return "0";
    final discount = 100 - (promoVal / priceVal * 100);
    
    // Native Parity: Android uses dynamic decimals for discount percentages based on distributor settings + CEILING rounding
    double multiplier = 1;
    for (int i = 0; i < decimalDigits; i++) {
        multiplier *= 10;
    }
    double rounded = (discount * multiplier).ceilToDouble() / multiplier;
    return rounded.toStringAsFixed(decimalDigits);
  }

  static String checkNullempty(String? value) {
    if (value == null || value.isEmpty || value == "null") {
      return "";
    }
    return value;
  }

  static bool hasValidImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == "null") return false;

    final lower = imageUrl.toLowerCase();
    // Common placeholder patterns observed in this project's backend
    if (lower.contains("no-image") ||
        lower.contains("no_image") ||
        lower.contains("noimage") ||
        lower.endsWith("backend/uploads/") ||
        lower.endsWith("backend/uploads")) {
      return false;
    }
    return true;
  }

  static String decodeHtmlEntities(String? text, {bool stripTags = true}) {
    return htmltag(text, stripTags: stripTags);
  }

  static String htmltag(String? text, {bool stripTags = true}) {
    if (text == null || text.trim().isEmpty) return "";
    try {
      // 1. Initial pass: Core entity replacement
      String intermediate = text
          .replaceAll("&nbsp;", " ")
          .replaceAll("&amp;", "&")
          .replaceAll("&lt;", "<")
          .replaceAll("&gt;", ">")
          .replaceAll("&quot;", "\"")
          .replaceAll("&apos;", "'");

      // 2. Parser pass: Use html package for robust entity and tag handling
      var document = html_parser.parse(intermediate);
      String decoded = stripTags ? (document.body?.text ?? intermediate) : (document.body?.innerHtml ?? intermediate);

      // 3. Double-pass check: If still containing common entities, decoding might be double-escaped
      if (!stripTags && (decoded.contains("&lt;") || decoded.contains("&gt;") || decoded.contains("&amp;"))) {
          var secondPassDoc = html_parser.parse(decoded);
          decoded = secondPassDoc.body?.innerHtml ?? decoded;
      }

      // 4. Cleanup pass: Strip tags if requested and normalize characters
      String finalResult = decoded;
      if (stripTags) {
        finalResult = finalResult.replaceAll(RegExp(r'<[^>]*>'), '');
      }
      finalResult = finalResult.replaceAll('\u00A0', ' '); // Normalize non-breaking space

      return finalResult.trim();
    } catch (e) {
      // Basic fallback
      String fallback = text ?? "";
      if (stripTags) {
        fallback = fallback.replaceAll(RegExp(r'<[^>]*>'), '');
      }
      return fallback
          .replaceAll("&nbsp;", " ")
          .replaceAll("&amp;", "&")
          .trim();
    }
  }

  static String calculateDiscount(String? original, String? promo) {
    if (original == null || promo == null) return "0";

    // Strip everything except digits and dots (Native Parity with findDiscount)
    String cleanOriginal = original.replaceAll(RegExp(r'[^0-9.]'), '');
    String cleanPromo = promo.replaceAll(RegExp(r'[^0-9.]'), '');

    double o = double.tryParse(cleanOriginal) ?? 0;
    double p = double.tryParse(cleanPromo) ?? 0;
    
    if (o <= 0) return "0";
    
    double discountPrice = p / o;
    double totalDisPrice = 100 - (discountPrice * 100);
    
    // Native Parity: Android uses dynamic decimals for discount percentages based on distributor settings + CEILING rounding
    double multiplier = 1;
    for (int i = 0; i < decimalDigits; i++) {
        multiplier *= 10;
    }
    double rounded = (totalDisPrice * multiplier).ceilToDouble() / multiplier;
    return rounded.toStringAsFixed(decimalDigits);
  }

  static double safeSize(double value, {double defaultValue = 0.0, double? min}) {
    if (value.isNaN || value.isInfinite) {
      return defaultValue;
    }
    if (min != null && value < min) {
      return min;
    }
    return value;
  }

  static String getTaxLabel(bool isExcl, {required String levy, required String wet, required String gst}) {
    List<String> labels = [];
    double l = double.tryParse(levy) ?? 0;
    double w = double.tryParse(wet) ?? 0;
    double g = double.tryParse(gst) ?? 0;

    String prefix = isExcl ? "Ex. " : "Inc. ";

    if (l > 0) labels.add("${prefix}Levy");
    if (w > 0) labels.add("${prefix}Wet");
    if (g > 0 || labels.isEmpty) labels.add("${prefix}GST");

    return "${labels.join(", ")} :";
  }

  static String formatApiLabel(String? label) {
    if (label == null || label.isEmpty || label == "null") return "";

    // Replace <br/> with newline if present
    String formatted =
        label.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Basic HTML tag stripping (if any other tags exist)
    formatted = formatted.replaceAll(RegExp(r'<[^>]*>'), '');

    // Trim and ensure colon at the end
    formatted = formatted.trim();
    if (formatted.isNotEmpty && !formatted.endsWith(':')) {
      formatted = "$formatted :";
    }

    return formatted;
  }

  static Future<String> getDeviceType() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        String manufacturer = androidInfo.manufacturer;
        String model = androidInfo.model;
        if (model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
          return model;
        }
        return "$manufacturer $model";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name; // e.g. "iPhone 13"
      }
    } catch (e) {
      debugPrint("Error getting device info: $e");
    }
    return Platform.operatingSystem;
  }

  static void showCompanyInActiveDialog(
      BuildContext context, String companyName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Inactive Company",
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey, size: 24.sp),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Text(
          "$companyName is inactive, so you cannot place this order.",
          style: TextStyle(fontSize: 14.sp, color: Colors.black87),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryButtonColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r)),
              ),
              child: Text("OK",
                  style: TextStyle(color: Colors.white, fontSize: 14.sp)),
            ),
          ),
        ],
      ),
    );
  }

  static String formatErrorMessage(dynamic error) {
    if (error == null) return "Unknown error occurred";
    String errorStr = error.toString();

    if (errorStr.contains("ClientException")) {
      if (errorStr.contains("Connection closed")) {
        return "Connection lost. Please check your internet and try again.";
      }
      return "Network error. Please try again later.";
    }

    if (errorStr.contains("SocketException")) {
      return "No Internet connection";
    }

    if (errorStr.contains("HttpException")) {
      return "Server error. Please try again later.";
    }

    // Handle "No Products Available" specifically if it's in the string but formatted as an exception
    if (errorStr.toLowerCase().contains("no products available")) {
        return "No Products Available";
    }

    return errorStr;
  }

  static Color _parseColor(String? hexColor, Color defaultColor) {
    if (hexColor == null || hexColor.isEmpty) return defaultColor;
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }

  static bool _isStoreDialogShowing = false;

  static void showStoreNotAvailableDialog(String reason, {Map<String, dynamic>? data}) {
    if (_isStoreDialogShowing) return;

    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;

    _isStoreDialogShowing = true;

    // Parse colors
    Color themeColor = AppTheme.tealColor;
    Color textColor = Colors.black87;
    
    if (data != null) {
      if (data['theme_color'] != null) {
        themeColor = _parseColor(data['theme_color'].toString(), themeColor);
      }
      if (data['text_color'] != null) {
        textColor = _parseColor(data['text_color'].toString(), textColor);
      }
    }

    final cleanReason = decodeHtmlEntities(reason, stripTags: false);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!context.mounted) {
        _isStoreDialogShowing = false;
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(safeSize(4.r, defaultValue: 4))),
          clipBehavior: Clip.antiAlias,
          insetPadding: EdgeInsets.symmetric(horizontal: safeSize(24.w, defaultValue: 24)),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  color: themeColor,
                  padding: EdgeInsets.symmetric(
                      horizontal: safeSize(16.w, defaultValue: 16), 
                      vertical: safeSize(12.h, defaultValue: 12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Alert",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: safeSize(16.sp, defaultValue: 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _isStoreDialogShowing = false;
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.close, color: Colors.white, 
                            size: safeSize(24.sp, defaultValue: 24)),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: EdgeInsets.only(
                      top: safeSize(24.h, defaultValue: 24), 
                      left: safeSize(16.w, defaultValue: 16), 
                      right: safeSize(16.w, defaultValue: 16), 
                      bottom: safeSize(20.h, defaultValue: 20)),
                  child: Html(
                    data: cleanReason,
                    style: {
                      "body": Style(
                        color: textColor,
                        fontSize: FontSize(safeSize(15.sp, defaultValue: 15)),
                        textAlign: TextAlign.center,
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                    },
                  ),
                ),

                // Button
                Padding(
                  padding: EdgeInsets.only(bottom: safeSize(24.h, defaultValue: 24)),
                  child: ElevatedButton(
                    onPressed: () {
                      _isStoreDialogShowing = false;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryButtonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(safeSize(4.r, defaultValue: 4))),
                      padding:
                          EdgeInsets.symmetric(
                              horizontal: safeSize(40.w, defaultValue: 40), 
                              vertical: safeSize(10.h, defaultValue: 10)),
                    ),
                    child: Text(
                      "Ok",
                      style:
                          TextStyle(
                              fontSize: safeSize(14.sp, defaultValue: 14), 
                              fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).then((_) {
        _isStoreDialogShowing = false;
      });
    });
  }

  static void showErrorPopup(BuildContext context, {
    required String title,
    required String subTitle,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
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
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
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
                  Image.asset(
                    'assets/images/mark.png',
                    width: 60.sp,
                    height: 60.sp,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    subTitle,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 2,
                      ),
                      child: Text(
                        "Close",
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

  static Future<void> showSuccessPopup(
    BuildContext context, {
    required String title,
    required String subTitle,
    required String message,
    int? autoCloseDuration,
  }) {
    if (autoCloseDuration != null) {
      Future.delayed(Duration(seconds: autoCloseDuration), () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
    return showDialog(
      context: context,
      barrierDismissible: true,
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
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
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
                  Image.asset(
                    'assets/images/greentickmark.png',
                    width: 60.sp,
                    height: 60.sp,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    subTitle,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryButtonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 2,
                      ),
                      child: Text(
                        "Close",
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
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'storage_keys.dart';
import '../../domain/entities/companies_response.dart';

/// Handles loading and applying company-specific theme colors.
///
/// Call [loadTheme] on app startup to restore persisted colors.
/// Call [applyFromCompany] when the user selects a company.
class AppThemeService {
  /// Reads stored color hex strings from [SharedPreferences] and applies them
  /// to [AppTheme]'s mutable dynamic color fields.
  /// After calling this, increment [AppTheme.themeNotifier] to trigger rebuilds.
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final textHex = prefs.getString(StorageKeys.companyTextColor);
    final hintHex = prefs.getString(StorageKeys.companyHintColor);
    final themeHex = prefs.getString(StorageKeys.companyThemeColor);
    final appbarHex = prefs.getString(StorageKeys.companyAppbarColor);
    final borderHex = prefs.getString(StorageKeys.companyBorderColor);
    final primaryButtonHex = prefs.getString(StorageKeys.companyPrimaryButtonColor);
    final secondaryButtonHex = prefs.getString(StorageKeys.companySecondaryButtonColor);

    AppTheme.dynamicTextColor =
        AppTheme.hexToColor(textHex, fallback: const Color(0xFF333333));
    AppTheme.dynamicHintColor =
        AppTheme.hexToColor(hintHex, fallback: const Color(0xFFBDBDBD));
    AppTheme.dynamicThemeColor =
        AppTheme.hexToColor(themeHex, fallback: AppTheme.primaryColor);
    AppTheme.dynamicAppbarColor =
        AppTheme.hexToColor(appbarHex, fallback: AppTheme.primaryColor);
    AppTheme.dynamicBorderColor =
        AppTheme.hexToColor(borderHex, fallback: const Color(0xFFBDBDBD));
    AppTheme.dynamicPrimaryButtonColor =
        AppTheme.hexToColor(primaryButtonHex, fallback: AppTheme.tealColor);
    AppTheme.dynamicSecondaryButtonColor =
        AppTheme.hexToColor(secondaryButtonHex, fallback: const Color(0xFF1D2671));

    // Signal listeners to rebuild with new colors
    AppTheme.themeNotifier.value++;
  }

  /// Persists the color fields from [company] to [SharedPreferences] and then
  /// applies them immediately via [loadTheme].
  static Future<void> applyFromCompany(CompanyResult company) async {
    final prefs = await SharedPreferences.getInstance();

    if (company.textColor != null && company.textColor!.isNotEmpty) {
      await prefs.setString(StorageKeys.companyTextColor, company.textColor!);
    } else {
      await prefs.remove(StorageKeys.companyTextColor);
    }
    if (company.hintColor != null && company.hintColor!.isNotEmpty) {
      await prefs.setString(StorageKeys.companyHintColor, company.hintColor!);
    } else {
      await prefs.remove(StorageKeys.companyHintColor);
    }
    if (company.themeColor != null && company.themeColor!.isNotEmpty) {
      await prefs.setString(StorageKeys.companyThemeColor, company.themeColor!);
    } else {
      await prefs.remove(StorageKeys.companyThemeColor);
    }
    if (company.appbarColor != null && company.appbarColor!.isNotEmpty) {
      await prefs.setString(StorageKeys.companyAppbarColor, company.appbarColor!);
    } else {
      await prefs.remove(StorageKeys.companyAppbarColor);
    }
    if (company.borderColor != null && company.borderColor!.isNotEmpty) {
      await prefs.setString(StorageKeys.companyBorderColor, company.borderColor!);
    } else {
      await prefs.remove(StorageKeys.companyBorderColor);
    }
    if (company.primaryButtonColor != null && company.primaryButtonColor!.isNotEmpty) {
      await prefs.setString(StorageKeys.companyPrimaryButtonColor, company.primaryButtonColor!);
    } else {
      await prefs.remove(StorageKeys.companyPrimaryButtonColor);
    }
    if (company.secondaryButtonColor != null && company.secondaryButtonColor!.isNotEmpty) {
      await prefs.setString(StorageKeys.companySecondaryButtonColor, company.secondaryButtonColor!);
    } else {
      await prefs.remove(StorageKeys.companySecondaryButtonColor);
    }

    await loadTheme();
  }
}

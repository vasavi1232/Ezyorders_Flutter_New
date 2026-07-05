import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/service_locator.dart';
import '../../core/constants/url_api_key.dart';
import '../../domain/entities/companies_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/constants/app_theme_service.dart';

class CompaniesProvider extends ChangeNotifier {
  bool _isLoading = true; // Start loading immediately as per Android init
  String? _errorMsg;
  List<CompanyResult> _companies = [];

  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  List<CompanyResult> get companies => _companies;

  final AuthRepository _repository = getIt<AuthRepository>();

  Future<void> fetchCompanies() async {
    // FIX: Reset Base URLs to default to ensure we hit the main server, not a specific store's domain
    UrlApiKey.companyMainUrl = "https://ezyorders.co.in/";
    UrlApiKey.mainUrl = "https://ezyorders.co.in/";

    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    try {
      final response = await _repository.getCompanies();

      if (response.status == 200) {
        final results = response.results;
        if (results != null && results.isNotEmpty) {
          // Filter companies based on platform visibility
          _companies = results.where((c) {
            final portalStr = c.showPortalIn ?? "";
            
            if (Platform.isAndroid) {
              return portalStr.contains("Android App");
            } else if (Platform.isIOS) {
              return portalStr.contains("IOS App");
            }
            
            // Default to showing if platform is not strictly mobile (e.g. web/desktop during dev)
            return true;
          }).toList();
          
          _isLoading = false;
          notifyListeners();
        } else {
          _isLoading = false;
          _errorMsg = "No data";
          notifyListeners();
        }
      } else {
        _isLoading = false;
        _errorMsg = response.message ?? "Error fetching companies";
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMsg = e.toString();
      notifyListeners();
    }
  }

  Future<void> selectCompany(
      BuildContext context, CompanyResult company) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
        StorageKeys.companyId, company.companyId?.toString() ?? "");
    await prefs.setString(StorageKeys.companyToken, company.accessToken ?? "");
    await prefs.setString(StorageKeys.companyUrl, company.companyUrl ?? "");
    await prefs.setString(StorageKeys.companyName, company.name ?? "");
    await prefs.setString(StorageKeys.companyImage, company.image ?? "");
    await prefs.setString(
        StorageKeys.paymentMethods, company.availablePaymentMethods ?? "");
    await prefs.setString(StorageKeys.emailRequired,
        company.emailRequiredForCustomerSignup ?? "");
    await prefs.setString(
        StorageKeys.razorSecretKey, company.razorPaySecret ?? "");
    await prefs.setString(
        StorageKeys.razorServerKey, company.razorPayKey ?? "");
    await prefs.setString(
        StorageKeys.companyRegisterNeeded, company.allowNewUserSignUp ?? "");
    await prefs.setString(StorageKeys.userNamePlaceholder,
        company.loginScreenUsernamePlaceholder ?? "");

    if (company.companyUrl != null && company.companyUrl!.isNotEmpty) {
      UrlApiKey.baseUrl = "${company.companyUrl}/api/";
    }

    // Apply and persist the company's brand colors
    await AppThemeService.applyFromCompany(company);

    if (context.mounted) {
      context.go('/login');
    }
  }
}

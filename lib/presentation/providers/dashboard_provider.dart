import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/session_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/home_models.dart' hide PromotionsResponse;
import '../../data/models/profile_models.dart';
import '../../data/models/drawer_models.dart';
import '../../data/models/wishlist_models.dart';
import '../../core/constants/storage_keys.dart';
import '../../../core/constants/url_api_key.dart';
import '../../core/constants/app_messages.dart';
import '../../core/utils/common_methods.dart';

class DashboardProvider extends ChangeNotifier {
  final AuthRemoteDataSource _dataSource;

  // State
  bool _isLoading = false;
  bool _isPromotionsLoading = false;
  bool _isPortalBlocked = false;
  String? _errorMsg;
  String? _accessToken;
  String? _companyName;
  String? _actionError; // Added for transient actions

  // Data Models
  ProfileResponse? _profileResponse;
  BannersResponse? _bannersResponse;
  FooterBannersResponse? _footerBannersResponse;
  HomeBlocksResponse? _homeBlocksResponse;

  // Section Data
  PromotionsResponse? _promotionsResponse;
  DashboardProductsResponse? _bestSellersResponse;
  FlashDealsResponse? _flashDealsResponse;
  DashboardProductsResponse? _newArrivalsResponse;
  DashboardProductsResponse? _hotSellingResponse;
  PopularCategoriesResponse? _popularCategoriesResponse;
  SupplierLogosResponse? _supplierLogosResponse;
  DashboardProductsResponse? _recentlyAddedResponse;
  PopularAdvertisementsResponse? _popularAdvertisementsResponse;

  // Wishlist State
  WishlistCategoriesResponse? _wishlistCategoriesResponse;
  bool _isFetchingWishlistCategories = false;
  // Company Config
  String? _companyImage;

  // Drawer Screens State
  NotificationResponse? _notificationsResponse;
  FAQResponse? _faqCategoriesResponse;
  FAQDetailsResponse? _faqDetailsResponse;
  AboutUsResponse? _aboutUsResponse;
  bool _isFetchingDrawerData = false;

  // Pagination Pages (Defaults to 1 as per Android)
  int promotionPage = 1;
  int bestSellersPage = 1;
  int flashDealsPage = 1;
  int newArrivalsPage = 1;
  int hotSellingPage = 1;
  int popularCategoriesPage = 1;
  int supplierLogosPage = 1;
  int recentlyAddedPage = 1;
  int popularAdsPage = 1;

  // Load More Flags
  bool isPromotionsLoadingMore = false;
  bool isBestSellersLoadingMore = false;
  bool isFlashDealsLoadingMore = false;
  bool isNewArrivalsLoadingMore = false;
  bool isHotSellingLoadingMore = false;
  bool isPopularCategoriesLoadingMore = false;
  bool isSupplierLogosLoadingMore = false;
  bool isRecentlyAddedLoadingMore = false;
  bool isPopularAdsLoadingMore = false;
  // Getters
  bool get isLoading => _isLoading;
  bool get isPromotionsLoading => _isPromotionsLoading;
  bool get isPortalBlocked => _isPortalBlocked;
  String? get errorMsg => _errorMsg;
  String? get actionError => _actionError;
  String? get accessToken => _accessToken;
  String? get companyName => _companyName;

  ProfileResponse? get profileResponse => _profileResponse;
  String get shippingSegmentHeading {
    final head = _profileResponse?.results?.firstOrNull?.shippingSegmentHeading;
    if (head == null || head.trim().isEmpty) {
      return "Choose Your Delivery Location";
    }
    return CommonMethods.decodeHtmlEntities(head, stripTags: true);
  }

  String get shippingSegmentText {
    final text = _profileResponse?.results?.firstOrNull?.shippingSegmentText;
    if (text == null || text.trim().isEmpty) {
      return "";
    }
    return CommonMethods.decodeHtmlEntities(text, stripTags: true);
  }

  String get subTotalHeading => CommonMethods.formatApiLabel(
      _profileResponse?.results?.firstOrNull?.subTotalHeading);
  String get totalHeading => CommonMethods.formatApiLabel(
      _profileResponse?.results?.firstOrNull?.totalHeading);

  String get taxLabel {
    final profile = _profileResponse?.results?.firstOrNull;
    if (profile?.showLevy == "Yes") return "Levy :";
    if (profile?.showWet == "Yes") return "WET :";
    return "GST :";
  }
  BannersResponse? get bannersResponse => _bannersResponse;
  FooterBannersResponse? get footerBannersResponse => _footerBannersResponse;
  HomeBlocksResponse? get homeBlocksResponse => _homeBlocksResponse;

  PromotionsResponse? get promotionsResponse => _promotionsResponse;
  DashboardProductsResponse? get bestSellersResponse => _bestSellersResponse;
  FlashDealsResponse? get flashDealsResponse => _flashDealsResponse;
  DashboardProductsResponse? get newArrivalsResponse => _newArrivalsResponse;
  DashboardProductsResponse? get hotSellingResponse => _hotSellingResponse;
  PopularCategoriesResponse? get popularCategoriesResponse =>
      _popularCategoriesResponse;
  SupplierLogosResponse? get supplierLogosResponse => _supplierLogosResponse;
  DashboardProductsResponse? get recentlyAddedResponse =>
      _recentlyAddedResponse;
  PopularAdvertisementsResponse? get popularAdvertisementsResponse =>
      _popularAdvertisementsResponse;
  String? get companyImage => _companyImage;
  String? get supplierLogosPosition =>
      _profileResponse?.results?[0]?.supplierLogosPosition;

  // Drawer Getters
  NotificationResponse? get notificationsResponse => _notificationsResponse;
  FAQResponse? get faqCategoriesResponse => _faqCategoriesResponse;
  FAQDetailsResponse? get faqDetailsResponse => _faqDetailsResponse;
  AboutUsResponse? get aboutUsResponse => _aboutUsResponse;
  bool get isFetchingDrawerData => _isFetchingDrawerData;

  // Wishlist Getters
  List<WishlistCategory?>? get wishlistCategories =>
      _wishlistCategoriesResponse?.results;
  bool get isFetchingWishlistCategories => _isFetchingWishlistCategories;

  DashboardProvider(this._dataSource);

  void clearPromotions() {
    _promotionsResponse = null;
    _isLoading = true;
    _isPromotionsLoading = true;
    notifyListeners();
  }

  void init({bool isSilent = false}) {
    if (!isSilent) {
      _isLoading = true;
    }
    _errorMsg = null;
    notifyListeners();

    // Android Logic: Profile Call FIRST
    _loadCompanyConfig();
    _fetchProfile();
  }

  Future<void> _fetchDashboardContent(ProfileResult profile) async {
    // Core sections that we MUST wait for to ensure "Real Data" consistency
    final List<Future> coreFutures = [];

    // Always wait for Banners and Home Blocks at the top
    coreFutures.add(_fetchBanners());
    coreFutures.add(_fetchHomeBlocks());

    // Always trigger Footer Banners and Promotions (non-blocking for speed)
    _fetchFooterBanners().then((_) => notifyListeners());
    fetchPromotions(page: 1, isSilent: true).then((_) => notifyListeners());

    // Conditional Core Sections (Wait for these as per User Request)
    if (profile.bestSellers == "Show") {
      coreFutures.add(_fetchBestSellers());
    }

    if (profile.hotSelling == "Show") {
      coreFutures.add(_fetchHotSelling());
    }

    if (profile.flashDeals == "Show") {
      coreFutures.add(_fetchFlashDeals());
    }

    if (profile.newArrivals == "Show") {
      coreFutures.add(_fetchNewArrivals());
    }

    // Other non-core sections (Trigger but don't wait)
    if (profile.productsAdvertisements == "Show") {
      _fetchPopularAdvertisements().then((_) => notifyListeners());
    }

    if (profile.supplierLogos == "Show") {
      _fetchSupplierLogos().then((_) => notifyListeners());
    }

    if (profile.popularCategories == "Show") {
      _fetchPopularCategories().then((_) => notifyListeners());
    }

    if (profile.recentlyAdded == "Show") {
      _fetchRecentlyAdded().then((_) => notifyListeners());
    }

    // Wait for all core sections to complete
    await Future.wait(coreFutures);

    // Final notification after core data is ready
    notifyListeners();
  }

  // Navigation State
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  String _cartQuantity = "0";
  String get cartQuantity => _cartQuantity;

  // Unread notification count – tracked locally so badge updates immediately
  // when user reads/deletes a notification, without waiting for a profile refresh.
  int _unreadNotificationCount = 0;
  int get unreadNotificationCount => _unreadNotificationCount;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setCartCount(String count) {
    _cartQuantity = count;
    notifyListeners();
  }

  Future<void> _loadCompanyConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _companyImage = prefs.getString(StorageKeys.companyImage);

      // Update Global URLs from Preferences (Android Parity)
      final companyUrl = prefs.getString(StorageKeys.companyUrl);
      if (companyUrl != null && companyUrl.isNotEmpty) {
        final cleanUrl = companyUrl.endsWith('/') ? companyUrl.substring(0, companyUrl.length - 1) : companyUrl;

        // Android: UrlApiKey.MAIN_URL = prefs.CompanyUrl + "/"
        UrlApiKey.mainUrl = "$cleanUrl/";
        UrlApiKey.companyMainUrl = "$cleanUrl/";

        // Android: UrlApiKey.BASE_URL = prefs.CompanyUrl + "/api/"
        UrlApiKey.baseUrl = "$cleanUrl/api/";

        debugPrint("Updated UrlApiKey.mainUrl to: ${UrlApiKey.mainUrl}");
      }
    } catch (e) {
      debugPrint("Error loading company config: $e");
    }
  }

  Future<void> refreshDashboard({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }
    await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      _accessToken = accessToken;
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      _companyName = prefs.getString(StorageKeys.companyName) ?? '';

      final response = await _dataSource.getProfile(accessToken, customerId);
      final status = response['status'];

      if (status != 200) {
        // Native Parity: If getProfile returns non-200, trigger logout (screenRedirection=12)
        getIt<SessionService>().notifySessionExpired();
        return;
      }

      _profileResponse = ProfileResponse.fromJson(response);

      if (_profileResponse?.results != null &&
          _profileResponse!.results!.isNotEmpty) {
        final profile = _profileResponse!.results![0]!;

        if (profile.emailRequiredForCustomerSignup != null &&
            profile.emailRequiredForCustomerSignup!.isNotEmpty) {
          await prefs.setString(StorageKeys.emailRequired,
              profile.emailRequiredForCustomerSignup!);
        }

        if (profile.priceDisplayType != null &&
            profile.priceDisplayType!.isNotEmpty) {
          CommonMethods.priceCode = profile.priceDisplayType!;
        }
        if (profile.priceDisplayTypeDecimals != null &&
            profile.priceDisplayTypeDecimals!.isNotEmpty) {
          CommonMethods.decimalDigits =
              int.tryParse(profile.priceDisplayTypeDecimals!) ?? 2;
        }

        _cartQuantity = _profileResponse?.cartQuantity ?? "0";
        CommonMethods.cartCount = _cartQuantity;
        CommonMethods.supplierCount =
            int.tryParse(_profileResponse?.suppliersCount ?? "0") ?? 0;
        CommonMethods.suppliers = _profileResponse?.suppliers ?? "";

        // Seed the local unread count from the profile API.
        _unreadNotificationCount = int.tryParse(
            _profileResponse?.results?.firstOrNull
                ?.unreadNotificationsCount ??
                "0") ??
            0;

        // Dynamic Company Logo Update: If customer_login_logo is present, update locally and in storage
        if (profile.customerLoginLogo != null &&
            profile.customerLoginLogo!.isNotEmpty) {
          _companyImage = profile.customerLoginLogo;
          await prefs.setString(
              StorageKeys.companyImage, profile.customerLoginLogo!);
          debugPrint("Updated company logo from profile: $_companyImage");
        }

        if (profile.showPortalIn != null) {
          if (Platform.isAndroid &&
              !profile.showPortalIn!.contains("Android App")) {
            _isPortalBlocked = true;
          } else if (Platform.isIOS &&
              !profile.showPortalIn!.contains("IOS App")) {
            _isPortalBlocked = true;
          } else {
            _isPortalBlocked = false;
          }
        }

        // Synchronize with core dashboard content
        await _fetchDashboardContent(profile);

        // Hide loader only after ALL core "Real Data" is ready
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(StorageKeys.accessToken);
    notifyListeners();
  }

  Future<void> _fetchBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final response = await _dataSource.getBanners(accessToken);
      _bannersResponse = BannersResponse.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching banners: $e");
    }
  }

  Future<void> _fetchFooterBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final response = await _dataSource.getFooterBanners(accessToken);
      _footerBannersResponse = FooterBannersResponse.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching footer banners: $e");
    }
  }

  Future<void> _fetchHomeBlocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final response = await _dataSource.getHomePageBlocks(accessToken);
      _homeBlocksResponse = HomeBlocksResponse.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching home blocks: $e");
    }
  }

  Future<void> fetchPromotions({int page = 1, bool isSilent = false}) async {
    _isPromotionsLoading = true;
    if (!isSilent) {
      _isLoading = true;
      if (page == 1) {
        _promotionsResponse = null; // Clear old data for fresh load
      }
    }
    notifyListeners();

    try {
      promotionPage = page;
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response =
      await _dataSource.getPromotions(accessToken, customerId, page);

      final newResponse = PromotionsResponse.fromJson(response);
      if (page == 1) {
        _promotionsResponse = newResponse;
      } else {
        if (_promotionsResponse?.results != null &&
            newResponse.results != null) {
          _promotionsResponse!.results!.addAll(newResponse.results!);
        }
      }
    } catch (e) {
      debugPrint("Error fetching promotions: $e");
    } finally {
      _isPromotionsLoading = false;
      if (!isSilent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void loadMorePromotions() {
    if (isPromotionsLoadingMore) return;
    if (promotionPage >= (_promotionsResponse?.totalPages ?? 1)) return;
    isPromotionsLoadingMore = true;
    notifyListeners();
    fetchPromotions(page: promotionPage + 1, isSilent: true).then((_) {
      isPromotionsLoadingMore = false;
      notifyListeners();
    });
  }

  Future<void> _fetchBestSellers({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isBestSellersLoadingMore) return;
      if (bestSellersPage >= (_bestSellersResponse?.totalPages ?? 1)) return;
      isBestSellersLoadingMore = true;
      bestSellersPage++;
      notifyListeners();
    } else {
      bestSellersPage = 1;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response = await _dataSource.getBestSellers(
          accessToken, customerId, bestSellersPage);
      final newResponse = DashboardProductsResponse.fromJson(response);

      // Filter Out Of Stock if setting is "No"
      final profile = _profileResponse?.results?.firstOrNull;
      if (profile?.showOutOfStockProducts == "No") {
        newResponse.results?.removeWhere((p) => p?.qtyStatus == "Out Of Stock");
      }

      if (isLoadMore) {
        _bestSellersResponse?.results?.addAll(newResponse.results ?? []);
      } else {
        _bestSellersResponse = newResponse;
      }
    } catch (e) {
      debugPrint("Error fetching best sellers: $e");
      if (isLoadMore) bestSellersPage--;
    } finally {
      if (isLoadMore) {
        isBestSellersLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void loadMoreBestSellers() {
    _fetchBestSellers(isLoadMore: true);
  }

  Future<void> _fetchFlashDeals({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFlashDealsLoadingMore) return;
      if (flashDealsPage >= (_flashDealsResponse?.totalPages ?? 1)) return;
      isFlashDealsLoadingMore = true;
      flashDealsPage++;
      notifyListeners();
    } else {
      flashDealsPage = 1;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response = await _dataSource.getFlashDeals(
          accessToken, customerId, flashDealsPage);
      final newResponse = FlashDealsResponse.fromJson(response);

      // Filter Out Of Stock if setting is "No"
      final profile = _profileResponse?.results?.firstOrNull;
      if (profile?.showOutOfStockProducts == "No") {
        newResponse.results?.removeWhere((p) => p?.qtyStatus == "Out Of Stock");
      }

      if (isLoadMore) {
        _flashDealsResponse?.results?.addAll(newResponse.results ?? []);
      } else {
        _flashDealsResponse = newResponse;
      }
    } catch (e) {
      debugPrint("Error fetching flash deals: $e");
      if (isLoadMore) flashDealsPage--;
    } finally {
      if (isLoadMore) {
        isFlashDealsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void loadMoreFlashDeals() {
    _fetchFlashDeals(isLoadMore: true);
  }

  Future<void> _fetchNewArrivals({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isNewArrivalsLoadingMore) return;
      if (newArrivalsPage >= (_newArrivalsResponse?.totalPages ?? 1)) return;
      isNewArrivalsLoadingMore = true;
      newArrivalsPage++;
      notifyListeners();
    } else {
      newArrivalsPage = 1;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response = await _dataSource.getNewArrivals(
          accessToken, customerId, newArrivalsPage);
      final newResponse = DashboardProductsResponse.fromJson(response);

      // Filter Out Of Stock if setting is "No"
      final profile = _profileResponse?.results?.firstOrNull;
      if (profile?.showOutOfStockProducts == "No") {
        newResponse.results?.removeWhere((p) => p?.qtyStatus == "Out Of Stock");
      }

      if (isLoadMore) {
        _newArrivalsResponse?.results?.addAll(newResponse.results ?? []);
      } else {
        _newArrivalsResponse = newResponse;
      }
    } catch (e) {
      debugPrint("Error fetching new arrivals: $e");
      if (isLoadMore) newArrivalsPage--;
    } finally {
      if (isLoadMore) {
        isNewArrivalsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void loadMoreNewArrivals() {
    _fetchNewArrivals(isLoadMore: true);
  }

  Future<void> _fetchHotSelling({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isHotSellingLoadingMore) return;
      if (hotSellingPage >= (_hotSellingResponse?.totalPages ?? 1)) return;
      isHotSellingLoadingMore = true;
      hotSellingPage++;
      notifyListeners();
    } else {
      hotSellingPage = 1;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response = await _dataSource.getHotSelling(
          accessToken, customerId, hotSellingPage);
      final newResponse = DashboardProductsResponse.fromJson(response);

      // Filter Out Of Stock if setting is "No"
      final profile = _profileResponse?.results?.firstOrNull;
      if (profile?.showOutOfStockProducts == "No") {
        newResponse.results?.removeWhere((p) => p?.qtyStatus == "Out Of Stock");
      }

      if (isLoadMore) {
        _hotSellingResponse?.results?.addAll(newResponse.results ?? []);
      } else {
        _hotSellingResponse = newResponse;
      }
    } catch (e) {
      debugPrint("Error fetching hot selling: $e");
      if (isLoadMore) hotSellingPage--;
    } finally {
      if (isLoadMore) {
        isHotSellingLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void loadMoreHotSelling() {
    _fetchHotSelling(isLoadMore: true);
  }

  Future<void> _fetchPopularCategories({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isPopularCategoriesLoadingMore) return;
      if (popularCategoriesPage >= (_popularCategoriesResponse?.totalPages ?? 1)) return;
      isPopularCategoriesLoadingMore = true;
      popularCategoriesPage++;
      notifyListeners();
    } else {
      popularCategoriesPage = 1;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response = await _dataSource.getPopularCategories(
          accessToken, customerId, popularCategoriesPage);
      final newResponse = PopularCategoriesResponse.fromJson(response);

      if (isLoadMore) {
        _popularCategoriesResponse?.results?.addAll(newResponse.results ?? []);
      } else {
        _popularCategoriesResponse = newResponse;
      }
    } catch (e) {
      debugPrint("Error fetching popular categories: $e");
      if (isLoadMore) popularCategoriesPage--;
    } finally {
      if (isLoadMore) {
        isPopularCategoriesLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void loadMorePopularCategories() {
    _fetchPopularCategories(isLoadMore: true);
  }

  Future<void> _fetchSupplierLogos({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isSupplierLogosLoadingMore) return;
      if (supplierLogosPage >= (_supplierLogosResponse?.totalPages ?? 1)) return;
      isSupplierLogosLoadingMore = true;
      supplierLogosPage++;
      notifyListeners();
    } else {
      supplierLogosPage = 1;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final response =
      await _dataSource.getSupplierLogos(accessToken, supplierLogosPage);
      final newResponse = SupplierLogosResponse.fromJson(response);

      if (isLoadMore) {
        _supplierLogosResponse?.results?.addAll(newResponse.results ?? []);
      } else {
        _supplierLogosResponse = newResponse;
      }
    } catch (e) {
      debugPrint("Error fetching supplier logos: $e");
      if (isLoadMore) supplierLogosPage--;
    } finally {
      if (isLoadMore) {
        isSupplierLogosLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void loadMoreSupplierLogos() {
    _fetchSupplierLogos(isLoadMore: true);
  }

  Future<void> _fetchRecentlyAdded({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isRecentlyAddedLoadingMore) return;
      if (recentlyAddedPage >= (_recentlyAddedResponse?.totalPages ?? 1)) return;
      isRecentlyAddedLoadingMore = true;
      recentlyAddedPage++;
      notifyListeners();
    } else {
      recentlyAddedPage = 1;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response = await _dataSource.getRecentlyAdded(
          accessToken, customerId, recentlyAddedPage);
      final newResponse = DashboardProductsResponse.fromJson(response);

      // Filter Out Of Stock if setting is "No"
      final profile = _profileResponse?.results?.firstOrNull;
      if (profile?.showOutOfStockProducts == "No") {
        newResponse.results?.removeWhere((p) => p?.qtyStatus == "Out Of Stock");
      }

      if (isLoadMore) {
        _recentlyAddedResponse?.results?.addAll(newResponse.results ?? []);
      } else {
        _recentlyAddedResponse = newResponse;
      }
    } catch (e) {
      debugPrint("Error fetching recently added: $e");
      if (isLoadMore) recentlyAddedPage--;
    } finally {
      if (isLoadMore) {
        isRecentlyAddedLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void loadMoreRecentlyAdded() {
    _fetchRecentlyAdded(isLoadMore: true);
  }

  Future<void> _fetchPopularAdvertisements({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isPopularAdsLoadingMore) return;
      if (popularAdsPage >= (_popularAdvertisementsResponse?.totalPages ?? 1)) return;
      isPopularAdsLoadingMore = true;
      popularAdsPage++;
      notifyListeners();
    } else {
      popularAdsPage = 1;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final response = await _dataSource.getPopularAdvertisements(
          accessToken, popularAdsPage);
      final newResponse = PopularAdvertisementsResponse.fromJson(response);

      if (isLoadMore) {
        _popularAdvertisementsResponse?.results?.addAll(newResponse.results ?? []);
      } else {
        _popularAdvertisementsResponse = newResponse;
      }
    } catch (e) {
      debugPrint("Error fetching popular advertisements: $e");
      if (isLoadMore) popularAdsPage--;
    } finally {
      if (isLoadMore) {
        isPopularAdsLoadingMore = false;
        notifyListeners();
      }
    }
  }

  void loadMorePopularAdvertisements() {
    _fetchPopularAdvertisements(isLoadMore: true);
  }

  // Wishlist Methods
  Future<void> fetchWishlistCategories(String productId) async {
    _isFetchingWishlistCategories = true;
    _wishlistCategoriesResponse = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await _dataSource.getWishlistCategories(
          accessToken, customerId, productId);
      _wishlistCategoriesResponse =
          WishlistCategoriesResponse.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching wishlist categories: $e");
      _errorMsg = "Failed to load wishlist categories";
    } finally {
      _isFetchingWishlistCategories = false;
      notifyListeners();
    }
  }

  void toggleWishlistCategory(String? categoryId) {
    if (_wishlistCategoriesResponse?.results == null) return;

    for (var category in _wishlistCategoriesResponse!.results!) {
      if (category == null) continue;
      if (category.categoryId == categoryId) {
        category.isSelected = !category.isSelected;
        break;
      }
    }
    notifyListeners();
  }

  Future<bool> submitWishlistUpdate(
      String productId, String newCategoryName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      // Collect selected category IDs
      String categoryIds = "";
      if (_wishlistCategoriesResponse?.results != null) {
        final selectedIds = _wishlistCategoriesResponse!.results!
            .where((c) => c?.isSelected == true)
            .map((c) => c?.categoryId)
            .whereType<String>();

        if (selectedIds.isNotEmpty) {
          // Android Parity: native code removes the trailing comma
          categoryIds = selectedIds.join(',');
        }
      }

      final response = await _dataSource.addToWishlist(
        accessToken: accessToken,
        customerId: customerId,
        productId: productId,
        categoryName: newCategoryName,
        categoryIds: categoryIds,
      );

      final addResponse = AddToWishlistResponse.fromJson(response);
      if (addResponse.status == 200) {
        // Update local favorite state (simplified: if any selected or new name provided)
        final isFav = categoryIds.isNotEmpty || newCategoryName.isNotEmpty;
        _updateProductFavoriteState(productId, isFav ? "Yes" : "No");

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _actionError = addResponse.message ??
            addResponse.successMessage ??
            "Failed to update wishlist";
      }
    } catch (e) {
      debugPrint("Error submitting wishlist update: $e");
      _actionError = "Failed to update wishlist";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  void _updateProductFavoriteState(String productId, String state) {
    // Update state in all loaded sections
    _bestSellersResponse?.results?.forEach((p) {
      if (p?.productId == productId) p?.isFavourite = state;
    });
    _hotSellingResponse?.results?.forEach((p) {
      if (p?.productId == productId) p?.isFavourite = state;
    });
    _newArrivalsResponse?.results?.forEach((p) {
      if (p?.productId == productId) p?.isFavourite = state;
    });
    _flashDealsResponse?.results?.forEach((p) {
      if (p?.productId == productId) p?.isFavourite = state;
    });
    _recentlyAddedResponse?.results?.forEach((p) {
      if (p?.productId == productId) p?.isFavourite = state;
    });
  }

  // Cart Methods
  Future<bool> addToCart(String productId, String qty, String price,
      String orderedAs, String apiData, String brandId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await _dataSource.addToCart(
          accessToken: accessToken,
          customerId: customerId,
          productId: productId,
          qty: qty,
          price: price,
          orderedAs: orderedAs,
          apiData: apiData);

      if (response['status'] == 200) {
        _updateProductCartState(productId, "Yes", qty, orderedAs: orderedAs);

        // Update Global Stats
        CommonMethods.cartCount =
            response['cart_quantity']?.toString() ?? CommonMethods.cartCount;
        CommonMethods.supplierCount =
            int.tryParse(response['suppliers_count']?.toString() ?? "0") ?? CommonMethods.supplierCount;
        CommonMethods.suppliers =
            response['suppliers']?.toString() ?? CommonMethods.suppliers;

        // Update Cart Count
        setCartCount(CommonMethods.cartCount);

        // Update Local Profile Suppliers State (Scenario requirement)
        // Update Local Profile Suppliers State (Scenario requirement)
        if (_profileResponse != null) {
          List<String> currentSuppliers =
              _profileResponse!.suppliers?.split(',') ?? [];
          if (currentSuppliers.length == 1 && currentSuppliers[0].isEmpty) {
            currentSuppliers = [];
          }

          if (!currentSuppliers.contains(brandId)) {
            currentSuppliers.add(brandId);
            _profileResponse!.suppliers = currentSuppliers.join(',');
            int count =
                int.tryParse(_profileResponse!.suppliersCount ?? "0") ?? 0;
            _profileResponse!.suppliersCount = (count + 1).toString();
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _actionError = response['message'] ?? "Failed to add to cart";
      }
    } catch (e) {
      debugPrint("Error adding to cart: $e");
      _actionError = "Failed to add to cart";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateCart(String productId, String qty, String brandId,
      String price, String orderedAs) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await _dataSource.updateCartItem(
          accessToken: accessToken,
          customerId: customerId,
          productId: productId,
          brandId: brandId,
          qty: qty,
          price: price,
          orderedAs: orderedAs);

      if (response['status'] == 200) {
        _updateProductCartState(productId, "Yes", qty, orderedAs: orderedAs);

        // Update Global Stats
        CommonMethods.cartCount =
            response['cart_quantity']?.toString() ?? CommonMethods.cartCount;
        CommonMethods.supplierCount =
            int.tryParse(response['suppliers_count']?.toString() ?? "0") ?? CommonMethods.supplierCount;
        CommonMethods.suppliers =
            response['suppliers']?.toString() ?? CommonMethods.suppliers;

        // Update Cart Count
        setCartCount(CommonMethods.cartCount);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _actionError = response['message'] ?? "Failed to update cart";
      }
    } catch (e) {
      debugPrint("Error updating cart: $e");
      _actionError = "Failed to update cart";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteCart(String productId, String brandId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await _dataSource.deleteCartItem(
          accessToken: accessToken,
          customerId: customerId,
          productId: productId,
          brandId: brandId);

      if (response['status'] == 200) {
        _updateProductCartState(productId, "No", "0");

        // Update Global Stats
        CommonMethods.cartCount =
            response['cart_quantity']?.toString() ?? CommonMethods.cartCount;
        CommonMethods.supplierCount =
            int.tryParse(response['suppliers_count']?.toString() ?? "0") ?? CommonMethods.supplierCount;
        CommonMethods.suppliers =
            response['suppliers']?.toString() ?? CommonMethods.suppliers;

        // Update Cart Count
        setCartCount(CommonMethods.cartCount);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _actionError = response['message'] ?? "Failed to delete from cart";
      }
    } catch (e) {
      debugPrint("Error deleting from cart: $e");
      _actionError = "Failed to delete from cart";
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  void _updateProductCartState(
      String productId, String addedToCart, String qty, {String? orderedAs}) {
    void update(ProductItem? p) {
      if (p?.productId == productId) {
        p?.addedToCart = addedToCart;
        p?.addedQty = qty;
        if (orderedAs != null) {
          p?.orderedAs = orderedAs;
        }
      }
    }

    _bestSellersResponse?.results?.forEach(update);
    _hotSellingResponse?.results?.forEach(update);
    _newArrivalsResponse?.results?.forEach(update);
    _flashDealsResponse?.results?.forEach(update);
    // Promotions do not have products directly in this list
    _recentlyAddedResponse?.results?.forEach(update);
  }

  // My Wishlist Logic
  List<ProductItem> _allWishlistItems = [];
  List<ProductItem> _filteredWishlistItems = [];
  List<ProductItem> get myWishlistItems => _filteredWishlistItems;

  List<WishlistCategory> _myWishlistCategories = [];
  List<WishlistCategory> get myWishlistCategories => _myWishlistCategories;

  String _selectedWishlistCategoryId = "";
  String get selectedWishlistCategoryId => _selectedWishlistCategoryId;

  bool _isFetchingMyWishlist = false;
  bool get isFetchingMyWishlist => _isFetchingMyWishlist;

  Future<void> fetchMyWishlist() async {
    if (_isFetchingMyWishlist) return;

    _isFetchingMyWishlist = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      // 1. Fetch Items
      final profileFuture = _dataSource.getProfile(accessToken, customerId);
      // 2. Fetch Categories
      final categoriesFuture =
      _dataSource.getGlobalWishlistCategories(accessToken, customerId);

      final results = await Future.wait([profileFuture, categoriesFuture]);

      // Process Items
      final profileResponse = ProfileResponse.fromJson(results[0]);
      if (profileResponse.results != null &&
          profileResponse.results!.isNotEmpty) {
        final result = profileResponse.results![0];
        if (result != null && result.wishlist != null) {
          _allWishlistItems = result.wishlist!
              .map((i) => ProductItem.fromJson(i as Map<String, dynamic>))
              .toList();

          // Filter Out Of Stock if setting is "No"
          if (result.showOutOfStockProducts == "No") {
            _allWishlistItems.removeWhere((p) => p.qtyStatus == "Out Of Stock");
          }
        } else {
          _allWishlistItems = [];
        }
      }

      // Process Categories
      try {
        final catResponse = WishlistCategoriesResponse.fromJson(results[1]);
        _myWishlistCategories =
            catResponse.results?.whereType<WishlistCategory>().toList() ?? [];
      } catch (e) {
        debugPrint("Error parsing global categories: $e");
        _myWishlistCategories = [];
      }

      _applyWishlistFilter();
    } catch (e) {
      debugPrint("Error fetching my wishlist: $e");
      _errorMsg = "Failed to load wishlist";
    } finally {
      _isFetchingMyWishlist = false;
      notifyListeners();
    }
  }

  void setSelectedWishlistCategory(String categoryId) {
    _selectedWishlistCategoryId = categoryId;
    _applyWishlistFilter();
    notifyListeners();
  }

  void _applyWishlistFilter() {
    if (_selectedWishlistCategoryId.isEmpty) {
      _filteredWishlistItems = List.from(_allWishlistItems);
    } else {
      _filteredWishlistItems = _allWishlistItems
          .where(
              (item) => item.wishlistCategoryId == _selectedWishlistCategoryId)
          .toList();

      // If the selected category has no items left, or it no longer exists in the list
      // of available categories, automatically fall back/redirect to "All Items".
      final bool categoryExists = _myWishlistCategories.any(
              (cat) => cat.categoryId == _selectedWishlistCategoryId);

      if (_filteredWishlistItems.isEmpty || !categoryExists) {
        _selectedWishlistCategoryId = "";
        _filteredWishlistItems = List.from(_allWishlistItems);
      }
    }
  }

  // Checkbox Selection Logic
  final Set<String> _selectedWishlistItemIds = {};
  final Map<String, int> _selectedWishlistQuantities = {};

  bool isWishlistItemSelected(String id) =>
      _selectedWishlistItemIds.contains(id);

  int getSelectedWishlistQuantity(String id) {
    return _selectedWishlistQuantities[id] ?? 1;
  }

  void toggleWishlistItemSelection(String wishlistId) {
    if (_selectedWishlistItemIds.contains(wishlistId)) {
      _selectedWishlistItemIds.remove(wishlistId);
      _selectedWishlistQuantities.remove(wishlistId);
    } else {
      _selectedWishlistItemIds.add(wishlistId);

      // Initialize with existing quantity or min order qty
      try {
        final item = _allWishlistItems.firstWhere((item) => item.wishlistId == wishlistId);
        int initialQty = 1;

        if (item.addedQty != null && item.addedQty != "0") {
          initialQty = int.tryParse(item.addedQty!) ?? 1;
        } else if (item.minimumOrderQty != null) {
          initialQty = int.tryParse(item.minimumOrderQty!) ?? 1;
        }

        _selectedWishlistQuantities[wishlistId] = initialQty;
      } catch (e) {
        _selectedWishlistQuantities[wishlistId] = 1;
      }
    }
    notifyListeners();
  }

  void incrementSelectedWishlistQuantity(String wishlistId) {
    if(!_selectedWishlistItemIds.contains(wishlistId)) return;

    try {
      final item = _allWishlistItems.firstWhere((item) => item.wishlistId == wishlistId);
      int currentQty = _selectedWishlistQuantities[wishlistId] ?? 1;
      int maxQty = 1000;

      if(item.stockUnlimited != "Yes" && item.qtyStatus != "Low In Stock"){
        maxQty = int.tryParse(item.availableStockQty ?? "100") ?? 100;
      }

      if(currentQty < maxQty) {
        _selectedWishlistQuantities[wishlistId] = currentQty + 1;
        notifyListeners();
      }
    } catch (e) {
      // Item not found or parse error
    }
  }

  void decrementSelectedWishlistQuantity(String wishlistId) {
    if(!_selectedWishlistItemIds.contains(wishlistId)) return;

    try {
      final item = _allWishlistItems.firstWhere((item) => item.wishlistId == wishlistId);
      int currentQty = _selectedWishlistQuantities[wishlistId] ?? 1;

      int minQty = 1;
      if(item.qtyStatus != "Out Of Stock" && item.minimumOrderQty != null) {
        minQty = int.tryParse(item.minimumOrderQty!) ?? 1;
      } else if(item.qtyStatus == "Out Of Stock") {
        minQty = int.tryParse(item.availableStockQty ?? "0") ?? 0;
      }

      if(currentQty > minQty && currentQty > 0) {
        _selectedWishlistQuantities[wishlistId] = currentQty - 1;
        notifyListeners();
      }
    } catch (e) {
      // Item not found or parse error
    }
  }

  Future<bool> addSelectedWishlistItemsToCart() async {
    if (_selectedWishlistItemIds.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      // Create a copy of the selected IDs to process sequentially
      final itemsToProcess = _selectedWishlistItemIds.toList();
      bool allSuccessful = true;

      for (String wId in itemsToProcess) {
        try {
          final item = _allWishlistItems.firstWhere((i) => i.wishlistId == wId);
          final qty = _selectedWishlistQuantities[wId] ?? 1;

          String price = item.price ?? "0";
          if (item.hasPromotion == "Yes" && item.promotionPrice != null) {
            price = item.promotionPrice!;
          }

          if (item.addedToCart == "Yes") {
            // Update Existing Cart Item
            final response = await _dataSource.updateCartItem(
              accessToken: accessToken,
              customerId: customerId,
              productId: item.productId ?? "",
              brandId: item.brandId ?? "",
              qty: qty.toString(),
              price: price,
              orderedAs: item.orderedAs ?? "",
            );
            if (response['status'] == 200) {
              CommonMethods.cartCount =
                  response['cart_quantity']?.toString() ?? CommonMethods.cartCount;
              CommonMethods.supplierCount =
                  int.tryParse(response['suppliers_count']?.toString() ?? "0") ?? CommonMethods.supplierCount;
              CommonMethods.suppliers =
                  response['suppliers']?.toString() ?? CommonMethods.suppliers;
            } else {
              allSuccessful = false;
            }
          } else {
            // Add New Cart Item
            final response = await _dataSource.addToCart(
              accessToken: accessToken,
              customerId: customerId,
              productId: item.productId ?? "",
              qty: qty.toString(),
              price: price,
              orderedAs: item.orderedAs ?? "",
              apiData: item.apiData ?? "",
            );
            if (response['status'] == 200) {
              CommonMethods.cartCount =
                  response['cart_quantity']?.toString() ?? CommonMethods.cartCount;
              CommonMethods.supplierCount =
                  int.tryParse(response['suppliers_count']?.toString() ?? "0") ?? CommonMethods.supplierCount;
              CommonMethods.suppliers =
                  response['suppliers']?.toString() ?? CommonMethods.suppliers;
            } else {
              allSuccessful = false;
            }
          }
        } catch (e) {
          allSuccessful = false;
        }
      }

      // Update global/local cart count state
      setCartCount(CommonMethods.cartCount);

      // Clear selections and quantities after successfully processing
      _selectedWishlistItemIds.clear();
      _selectedWishlistQuantities.clear();

      // Refresh the wishlist to get the latest addedToCart states
      await fetchMyWishlist();

      return allSuccessful;
    } catch (e) {
      debugPrint("Error processing bulk cart addition: $e");
      _actionError = "Failed to process selected items";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteWishlistItem(String wishlistId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await _dataSource.deleteFromWishlist(
        accessToken: accessToken,
        customerId: customerId,
        wishlistId: wishlistId,
      );

      final jsonResponse = response;
      if (jsonResponse['status'] == 200) {
        String? productIdToRemove;
        try {
          final item = _allWishlistItems
              .firstWhere((item) => item.wishlistId == wishlistId);
          productIdToRemove = item.productId;
        } catch (e) {
          // Item not found
        }

        _allWishlistItems.removeWhere((item) => item.wishlistId == wishlistId);

        if (productIdToRemove != null) {
          _updateProductFavoriteState(productIdToRemove, "No");
        }

        // Fetch fresh state to sync categories and remove any categories that are now empty
        await fetchMyWishlist();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _actionError = jsonResponse['message'] ?? "Failed to delete item";
      }
    } catch (e) {
      debugPrint("Error deleting wishlist item: $e");
      _actionError = "Failed to delete item";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Drawer Methods

  Future<void> fetchNotifications(int page) async {
    try {
      if (page == 1) _isFetchingDrawerData = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(StorageKeys.accessToken) ?? "";
      String customerId = prefs.getString(StorageKeys.userId) ?? "";

      final response =
      await _dataSource.getNotifications(token, customerId, page);
      if (page == 1) {
        _notificationsResponse = NotificationResponse.fromJson(response);
      } else {
        if (_notificationsResponse?.results != null &&
            response['results'] != null) {
          final newPage = NotificationResponse.fromJson(response);
          _notificationsResponse!.results!.addAll(newPage.results!);
        }
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isFetchingDrawerData = false;
      notifyListeners();
    }
  }

  Future<bool> changeNotificationStatus(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(StorageKeys.accessToken) ?? "";
      String customerId = prefs.getString(StorageKeys.userId) ?? "";

      await _dataSource.changeNotificationStatus(
          token, customerId, notificationId);

      // Update local state & decrement badge count if it was unread.
      if (_notificationsResponse?.results != null) {
        final index = _notificationsResponse!.results!
            .indexWhere((n) => n.notificationId == notificationId);
        if (index != -1) {
          final wasUnread =
              _notificationsResponse!.results![index].status == "UnRead";
          _notificationsResponse!.results![index].status = "Read";
          if (wasUnread && _unreadNotificationCount > 0) {
            _unreadNotificationCount--;
          }
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      debugPrint("Error changing notification status: $e");
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(StorageKeys.accessToken) ?? "";
      String customerId = prefs.getString(StorageKeys.userId) ?? "";

      await _dataSource.deleteNotification(token, customerId, notificationId);

      // Decrement badge if a still-unread notification is being deleted.
      final deleteIndex = _notificationsResponse?.results
          ?.indexWhere((n) => n.notificationId == notificationId) ?? -1;
      if (deleteIndex != -1 &&
          _notificationsResponse!.results![deleteIndex].status == "UnRead" &&
          _unreadNotificationCount > 0) {
        _unreadNotificationCount--;
      }

      // Update local list
      _notificationsResponse?.results
          ?.removeWhere((element) => element.notificationId == notificationId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("Error deleting notification: $e");
      return false;
    }
  }

  Future<void> fetchFAQCategories() async {
    try {
      _isFetchingDrawerData = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(StorageKeys.accessToken) ?? "";

      final response = await _dataSource.getFAQCategories(token);
      _faqCategoriesResponse = FAQResponse.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching FAQ categories: $e");
    } finally {
      _isFetchingDrawerData = false;
      notifyListeners();
    }
  }

  Future<void> fetchFAQDetails(String categoryId, int page) async {
    try {
      if (page == 1) _isFetchingDrawerData = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(StorageKeys.accessToken) ?? "";

      final response = await _dataSource.getFAQDetails(token, categoryId, page);
      if (page == 1) {
        _faqDetailsResponse = FAQDetailsResponse.fromJson(response);
      } else {
        if (_faqDetailsResponse?.results != null &&
            response['results'] != null) {
          final newPage = FAQDetailsResponse.fromJson(response);
          _faqDetailsResponse!.results!.addAll(newPage.results!);
        }
      }
    } catch (e) {
      debugPrint("Error fetching FAQ details: $e");
    } finally {
      _isFetchingDrawerData = false;
      notifyListeners();
    }
  }

  Future<void> fetchAboutUs() async {
    try {
      _isFetchingDrawerData = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(StorageKeys.accessToken) ?? "";

      final response = await _dataSource.getAboutUs(token);
      _aboutUsResponse = AboutUsResponse.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching About Us: $e");
    } finally {
      _isFetchingDrawerData = false;
      notifyListeners();
    }
  }

  Future<bool> sendFeedback({
    required String name,
    required String email,
    required String phone,
    required String subject,
    required String message,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _dataSource.sendFeedback(
        name: name,
        email: email,
        phone: phone,
        subject: subject,
        message: message,
      );

      _isLoading = false;
      notifyListeners();

      if (response['status'] == 200 || response['status'] == 1) {
        return true;
      } else {
        _actionError =
            response['message']?.toString() ?? "Failed to send feedback";
        return false;
      }
    } catch (e) {
      debugPrint("Error sending feedback: $e");
      _actionError = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // FIX: Reset Base URLs
      UrlApiKey.companyMainUrl = "https://ezyorders.co.in/";
      UrlApiKey.mainUrl = "https://ezyorders.co.in/";

      // Clear Crucial Auth Data
      await prefs.setString(StorageKeys.userId, "0");
      await prefs.setString(StorageKeys.accessToken, "");

      // Reset Provider State
      _profileResponse = null;
      _bannersResponse = null;
      _footerBannersResponse = null;
      _homeBlocksResponse = null;
      _promotionsResponse = null;
      _bestSellersResponse = null;
      _flashDealsResponse = null;
      _newArrivalsResponse = null;
      _hotSellingResponse = null;
      _popularCategoriesResponse = null;
      _supplierLogosResponse = null;
      _recentlyAddedResponse = null;
      _popularAdvertisementsResponse = null;
      _notificationsResponse = null;
      _faqCategoriesResponse = null;
      _faqDetailsResponse = null;
      _aboutUsResponse = null;

      notifyListeners();
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }

  // Profile Update Methods
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String mobile,
    required String email,
    required String street,
    required String street2,
    required String suburb,
    required String state,
    required String postcode,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      final response = await _dataSource.editProfile(
          accessToken: accessToken,
          customerId: customerId,
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
          email: email,
          street: street,
          street2: street2,
          suburb: suburb,
          state: state,
          postcode: postcode);

      if (response['status'] == 200) {
        // Update local profile
        if (_profileResponse?.results != null &&
            _profileResponse!.results!.isNotEmpty) {
          var p = _profileResponse!.results![0];
          p?.firstName = firstName;
          p?.lastName = lastName;
          p?.mobile = mobile;
          p?.phone = mobile;
          p?.email = email;
          p?.street = street;
          p?.street2 = street2;
          p?.suburb = suburb;
          p?.state = state;
          p?.postcode = postcode;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _actionError = response['message'] ?? AppMessages.failureMsg;
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      _actionError = AppMessages.failureMsg;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfileImage(File imageFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';

      // 1. Upload Image
      final uploadResponse =
      await _dataSource.imageFileUpload(imageFile, accessToken, customerId);

      if (uploadResponse['status'] == 200) {
        final imageName = uploadResponse['image_name'];

        // 2. Update Profile with Image Name
        if (_profileResponse?.results != null &&
            _profileResponse!.results!.isNotEmpty) {
          var p = _profileResponse!.results![0];
          final response = await _dataSource.editProfileImage(
              accessToken: accessToken,
              customerId: customerId,
              firstName: p?.firstName ?? "",
              lastName: p?.lastName ?? "",
              mobile: p?.mobile ?? "",
              email: p?.email ?? "",
              street: p?.street ?? "",
              street2: p?.street2 ?? "",
              suburb: p?.suburb ?? "",
              state: p?.state ?? "",
              postcode: p?.postcode ?? "",
              imageName: imageName);

          if (response['status'] == 200) {
            await _fetchProfile(); // Refresh profile to sync correct server-side image path
            return true;
          } else {
            _actionError = response['message'];
          }
        }
      } else {
        _actionError = uploadResponse['message'] ?? AppMessages.failureMsg;
      }
    } catch (e) {
      debugPrint("Error updating profile image: $e");
      _actionError = AppMessages.failureMsg;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _actionError = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final savedPassword = prefs.getString(StorageKeys.userPassword) ?? '';

      // Local Validation matching Android Native
      if (oldPassword != savedPassword) {
        _actionError = AppMessages.pleaseEnterValidPassword;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _dataSource.changePassword(
        accessToken: accessToken,
        customerId: customerId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (response['status'] == 200) {
        // Update local saved password upon success
        await prefs.setString(StorageKeys.userPassword, newPassword);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _actionError = response['message'] ?? AppMessages.failureMsg;
      }
    } catch (e) {
      debugPrint("Error changing password: $e");
      _actionError = AppMessages.failureMsg;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>> getCloseAccountMessage() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response = await _dataSource.closeAccountMessage(
        accessToken: accessToken,
        customerId: customerId,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint("Error fetching close account message: $e");
      _isLoading = false;
      notifyListeners();
      return {'status': 500, 'message': 'error'};
    }
  }

  Future<Map<String, dynamic>> closeAccount(String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? '';
      final customerId = prefs.getString(StorageKeys.userId) ?? '';
      final response = await _dataSource.closeAccount(
        accessToken: accessToken,
        customerId: customerId,
        reason: reason,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint("Error closing account: $e");
      _isLoading = false;
      notifyListeners();
      return {'status': 500, 'message': 'error'};
    }
  }
}

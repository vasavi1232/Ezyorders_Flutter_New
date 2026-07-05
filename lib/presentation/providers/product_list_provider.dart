import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/common_methods.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/product_models.dart';
import '../../data/models/home_models.dart';
import '../../data/models/profile_models.dart';

class ProductListProvider extends ChangeNotifier {
  final AuthRemoteDataSource _remoteDataSource;

  ProductListProvider(this._remoteDataSource);

  // State
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isDetailsLoading = false;
  bool get isDetailsLoading => _isDetailsLoading;

  ProductsResponse? _productsResponse;
  ProductsResponse? get productsResponse => _productsResponse;

  FilterProductResponse? _filterProductResponse;
  FilterProductResponse? get filterProductResponse => _filterProductResponse;

  FilterProductResponse? _allFilterProductResponse; // Popular/Default filters
  FilterProductResponse? get allFilterProductResponse =>
      _allFilterProductResponse;

  ProductSortResponse? _productSortResponse;
  ProductSortResponse? get productSortResponse => _productSortResponse;

  ProductDetailItem? _productDetailItem;
  ProductDetailItem? get productDetailItem => _productDetailItem;

  List<ProductItem> _products = [];
  List<ProductItem> get products => _products;

  List<ProductItem?>? _similarProducts;
  List<ProductItem?>? get similarProducts => _similarProducts;

  List<ProductItem?>? _sameCategoryProducts;
  List<ProductItem?>? get sameCategoryProducts => _sameCategoryProducts;

  bool _isSimilarLoading = false;
  bool get isSimilarLoading => _isSimilarLoading;

  bool _isSameCategoryLoading = false;
  bool get isSameCategoryLoading => _isSameCategoryLoading;

  int _similarPage = 1;
  int get similarPage => _similarPage;

  int _sameCategoryPage = 1;
  int get sameCategoryPage => _sameCategoryPage;

  bool _hasMoreSimilar = true;
  bool get hasMoreSimilar => _hasMoreSimilar;

  bool _hasMoreSameCategory = true;
  bool get hasMoreSameCategory => _hasMoreSameCategory;

  int _pageCount = 1;
  int get pageCount => _pageCount;

  String _searchText = "";
  String get searchText => _searchText;

  bool _isGridView = false;
  bool get isGridView => _isGridView;

  String _errorMsg = "";
  String get errorMsg => _errorMsg;

  bool get isFilterApplied {
    return CommonMethods.supplierIDs != CommonMethods.firstSuppliers ||
        CommonMethods.categoryIDs != CommonMethods.firstCatIds ||
        CommonMethods.tagIDs != CommonMethods.firstTags ||
        CommonMethods.groupIDs != CommonMethods.firstGroupids ||
        CommonMethods.selecetedProducts != CommonMethods.firstSelProds;
  }

  bool get isSortApplied {
    return CommonMethods.sortIDs != "";
  }

  String? _accessToken;
  String? _customerId;
  String? _accountNum;
  String _showOutOfStockProducts = "Yes";

  // Filter Lists
  List<FilterDivision> get divisionslist {
    return _filterProductResponse?.divisions
            ?.whereType<FilterDivision>()
            .toList() ??
        [];
  }

  List<FilterGroup> get groupslist {
    return _filterProductResponse?.groups?.whereType<FilterGroup>().toList() ??
        [];
  }

  List<FilterSupplier> get supplierslist =>
      _filterProductResponse?.suppliers?.whereType<FilterSupplier>().toList() ??
      [];

  List<FilterTag> get tagslist =>
      _filterProductResponse?.tags?.whereType<FilterTag>().toList() ?? [];

  List<FilterSubGroup> get subGroupslist {
    return _filterProductResponse?.subGroups
            ?.whereType<FilterSubGroup>()
            .toList() ??
        [];
  }
  List<SortItem> get sortList =>
      _productSortResponse?.results?.whereType<SortItem>().toList() ?? [];

  String _divisionName = "";
  String get divisionName => _divisionName;

  String _groupName = "";
  String get groupName => _groupName;

  // Tracks which filter section triggered the last fetchAllFilterOptions call.
  // "divisions" = category toggled inside filter dialog → only update suppliers/tags.
  String _filterType = "";
  String get filterType => _filterType;

  // True while the filter API is re-fetching due to a category toggle.
  bool _isFilterRefreshing = false;
  bool get isFilterRefreshing => _isFilterRefreshing;

  Widget? _activeHeaderWidget;
  Widget? get activeHeaderWidget => _activeHeaderWidget;

  void setActiveHeader(Widget? header) {
    _activeHeaderWidget = header;
    notifyListeners();
  }

  // Initialize and fetch initial data matching ProductListViewModel.kt init
  Future<void> init({bool? isTablet, ProfileResult? profile}) async {
    if (isTablet != null && profile != null) {
      initViewMode(isTablet, profile);
      _showOutOfStockProducts = profile.showOutOfStockProducts ?? "Yes";
    }
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(StorageKeys.accessToken) ?? "";
    _customerId = prefs.getString(StorageKeys.userId) ?? "0";
    _accountNum = prefs.getString(StorageKeys.customerAccountNum) ?? "";

    // Logic matching Handler(Looper.getMainLooper()).postDelayed in Android
    if (CommonMethods.productsBack == "suppliers") {
      CommonMethods.groupIDs = "";
      CommonMethods.selecetedProducts = "";
    } else if (CommonMethods.productsBack == "Banners") {
      // Keep values from CommonMethods
    } else {
      if (CommonMethods.productsBack != "dashboard_popcat") {
        CommonMethods.groupIDs = "";
      }
      _searchText = "";
      CommonMethods.selecetedProducts = "";
    }

    if (CommonMethods.selectFirstTime == "Yes") {
      CommonMethods.supplierIDs = CommonMethods.firstSuppliers;
      CommonMethods.groupIDs = CommonMethods.firstGroupids;
      CommonMethods.categoryIDs = CommonMethods.firstCatIds;
      CommonMethods.selecetedProducts = CommonMethods.firstSelProds;
      CommonMethods.tagIDs = CommonMethods.firstTags;
      CommonMethods.selectFirstTime = "";
    }

    if (CommonMethods.productsBack == "Banners" ||
        CommonMethods.productsBack == "suppliers") {
      await fetchAllFilterOptions("1");
    } else {
      if (CommonMethods.productsBack == "dashboard_popcat") {
        await fetchAllFilterOptionsPopular();
      } else {
        await fetchAllFilterOptionsDefault();
      }
    }
  }

  Future<void> fetchAllFilterOptionsDefault() async {
    _setLoading(true);
    try {
      final response = await _remoteDataSource.getAllFilterProducts(
        accessToken: _accessToken!,
        customerId: _customerId!,
        productsType: CommonMethods.filterSelected,
      );
      _allFilterProductResponse = FilterProductResponse.fromJson(response);

      // Chaining logic from Android
      await fetchAllFilterOptions("0");
    } catch (e) {
      _errorMsg = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchAllFilterOptionsPopular() async {
    _setLoading(true);
    try {
      String divisionId = "";
      String selectedDivisions = "";
      if (CommonMethods.categoryIDs.contains(",")) {
        selectedDivisions = CommonMethods.categoryIDs;
      } else {
        divisionId = CommonMethods.categoryIDs;
      }

      final response = await _remoteDataSource.getAllFilterProducts(
        accessToken: _accessToken!,
        customerId: _customerId!,
        divisionId: divisionId,
        selectedDivisions: selectedDivisions,
        productsType: CommonMethods.filterSelected,
      );
      _allFilterProductResponse = FilterProductResponse.fromJson(response);

      await fetchAllFilterOptions("3");
    } catch (e) {
      _errorMsg = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchAllFilterOptions(String type) async {
    // When triggered by a category (division or group) toggle inside the filter 
    // dialog, we only want to refresh suppliers/tags — not show the full-screen 
    // loader or re-fetch products. Use a lightweight refreshing flag instead.
    if (_filterType == "divisions" || _filterType == "groups") {
      _isFilterRefreshing = true;
      notifyListeners();
    } else if (type == "1" || type == "2") {
      _setLoading(true);
    }

    try {
      String divisionId = "";
      String selectedDivisions = "";
      String brandId = "";
      String selectedBrands = "";
      String groupId = "";
      String selectedGroups = "";

      if (CommonMethods.supplierIDs.contains(",")) {
        selectedBrands = CommonMethods.supplierIDs;
      } else {
        brandId = CommonMethods.supplierIDs;
      }

      // division filter matching Android logic
      if (CommonMethods.productsBack != "suppliers") {
        if (CommonMethods.categoryIDs.contains(",")) {
          selectedDivisions = CommonMethods.categoryIDs;
        } else {
          divisionId = CommonMethods.categoryIDs;
        }
      }

      // group filter matching Android logic
      if ((CommonMethods.productsBack == "dashboard_popcat" &&
              (type == "2" || type == "3")) ||
          CommonMethods.productsBack == "Banners") {
        if (CommonMethods.groupIDs.contains(",")) {
          selectedGroups = CommonMethods.groupIDs;
        } else {
          groupId = CommonMethods.groupIDs;
        }
      }

      developer.log(
        "Sending filter options request. filterType: $_filterType, "
        "divisionId: '$divisionId', selectedDivisions: '$selectedDivisions', "
        "groupId: '$groupId', selectedGroups: '$selectedGroups', "
        "subGroupIDs: '${CommonMethods.subGroupIDs}', "
        "productsBack: '${CommonMethods.productsBack}'",
        name: 'FilterDebug',
      );

      final response = await _remoteDataSource.getAllFilterProducts(
        accessToken: _accessToken!,
        customerId: _customerId!,
        divisionId: divisionId,
        brandId: brandId,
        selectedBrands: selectedBrands,
        groupId: groupId,
        subGroupId: CommonMethods.subGroupIDs,
        subSubGroupId: CommonMethods.subSubGroupIDs,
        selectedDivisions: selectedDivisions,
        selectedGroups: selectedGroups,
        selectedSubGroups: _getSubGroupIds(),
        selectedSubSubGroups: "", // Not yet implemented in UI
        selectedProducts: CommonMethods.selecetedProducts,
        productsType: CommonMethods.filterSelected,
      );

      developer.log("getAllFilterProducts response received. Status: ${response['status']}", name: 'FilterDebug');
      // developer.log("Full response: $response", name: 'FilterDebug'); // Keep commented if too long

      // ── filterType == "divisions" or "groups": a category was toggled inside 
      // the filter dialog. Android native behaviour: update suppliers + tags list 
      // in the dialog WITHOUT touching the categories list (user just edited it) 
      // and WITHOUT fetching products.
      if (_filterType == "divisions" ||
          _filterType == "groups" ||
          _filterType == "subGroups") {
        final freshFilter = FilterProductResponse.fromJson(response);

        // Re-read the divisionName from the response.
        if (freshFilter.divisionNames != null &&
            freshFilter.divisionNames!.isNotEmpty) {
          _divisionName = freshFilter.divisionNames![0]?.groupLevel1 ?? "";
        }
        if (freshFilter.groupNames != null &&
            freshFilter.groupNames!.isNotEmpty) {
          _groupName = freshFilter.groupNames![0]?.groupLevel2 ?? "";
        }

        // Keep the currently-selected supplier IDs so the checkboxes stay ticked.
        final previouslySelectedSupplierIds = _filterProductResponse?.suppliers
                ?.where((s) => s?.selected == "Yes")
                .map((s) => s?.brandId)
                .toSet() ??
            {};

        // Replace ONLY suppliers + tags + divisionName
        if (_filterProductResponse != null) {
          _filterProductResponse!.suppliers = freshFilter.suppliers;
          _filterProductResponse!.tags = freshFilter.tags;

          developer.log(
              "Updated suppliers/tags only. New suppliers count: ${freshFilter.suppliers?.length}",
              name: 'FilterDebug');
        }

        // Re-apply previous supplier selections so they stay checked.
        _filterProductResponse?.suppliers?.forEach((s) {
          if (previouslySelectedSupplierIds.contains(s?.brandId)) {
            s?.selected = "Yes";
          }
        });

        // Rebuild supplier IDs string to stay in sync.
        _updateBrandIds();

        _filterType = ""; // Reset
        _isFilterRefreshing = false;
        notifyListeners();
        return;
      }

      _filterProductResponse = FilterProductResponse.fromJson(response);

      if (_filterProductResponse?.divisionNames != null &&
          _filterProductResponse!.divisionNames!.isNotEmpty) {
        _divisionName =
            _filterProductResponse!.divisionNames![0]?.groupLevel1 ?? "";
      } else {
        _divisionName = "";
      }

      if (_filterProductResponse?.groupNames != null &&
          _filterProductResponse!.groupNames!.isNotEmpty) {
        _groupName = _filterProductResponse!.groupNames![0]?.groupLevel2 ?? "";
      } else {
        _groupName = "";
      }

      if (type == "first" || type == "1" || type == "0" || type == "3") {
        // type first logic
        await fetchProductSortOptions();
      } else if (type == "show") {
        await fetchProducts(page: 1);
      } else {
        _setLoading(false);
      }
    } catch (e) {
      _filterType = "";
      _isFilterRefreshing = false;
      _errorMsg = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchProductSortOptions() async {
    try {
      final response = await _remoteDataSource.getProductSortOptions(
          _accessToken!, _customerId!);
      _productSortResponse = ProductSortResponse.fromJson(response);

      if (_productSortResponse?.status == 200) {
        // Continue to fetching products
        await fetchProducts(page: 1);
      } else {
        await fetchProducts(page: 1);
      }
    } catch (e) {
      debugPrint("Sort options error: $e");
      await fetchProducts(page: 1);
    }
  }

  Future<void> fetchProducts(
      {required int page, bool isLoadMore = false}) async {
    if (isLoadMore && _isLoading) return;

    _setLoading(true);

    if (!isLoadMore) {
      _products = [];
      _pageCount = 1;
    }

    try {
      final response = await _remoteDataSource.getProducts(
        accessToken: _accessToken!,
        customerId: _customerId!,
        brandId: CommonMethods.supplierIDs,
        divisionId: CommonMethods.categoryIDs,
        groupId: CommonMethods.groupIDs,
        subGroupId: CommonMethods.subGroupIDs,
        subSubGroupId: CommonMethods.subSubGroupIDs,
        page: page,
        orderby: CommonMethods.sortIDs,
        tagId: CommonMethods.tagIDs,
        productsType: CommonMethods.filterSelected == "Show Products" ? "" : CommonMethods.filterSelected,
        searchText: _searchText,
        products: CommonMethods.selecetedProducts,
      );

      _productsResponse = ProductsResponse.fromJson(response);
      developer.log("Fetched ${_productsResponse?.results?.length} products", name: 'ProductListDebug');

      if (_productsResponse?.status == 200) {
        List<ProductItem> fetchedProducts =
            _productsResponse?.results?.whereType<ProductItem>().toList() ?? [];

        // Filter Out Of Stock if setting is "No"
        if (_showOutOfStockProducts == "No") {
          fetchedProducts.removeWhere((p) => p.qtyStatus == "Out Of Stock");
          developer.log("Filtered to ${fetchedProducts.length} products (Out of Stock hidden)", name: 'ProductListDebug');
        }

        if (isLoadMore) {
          _products.addAll(fetchedProducts);
          _pageCount = page;
        } else {
          _products = fetchedProducts;
        }
      } else {
        if (!isLoadMore) _products = [];
      }
      _setLoading(false);
    } catch (e) {
      developer.log("Error in fetchProducts: $e", name: 'ProductListDebug');
      _errorMsg = e.toString();
      _setLoading(false);
    }
  }

  Future<void> fetchProductDetails(String productId) async {
    _isDetailsLoading = true;
    _setLoading(true);
    _productDetailItem = null;
    _similarProducts = null;
    _sameCategoryProducts = null;
    _isSimilarLoading = false;
    _isSameCategoryLoading = false;
    _similarPage = 1;
    _sameCategoryPage = 1;
    _hasMoreSimilar = true;
    _hasMoreSameCategory = true;
    try {
      final response = await _remoteDataSource.getProductDetails(
          _accessToken!, _customerId!, productId);
      final detailsResponse = ProductDetailsResponse.fromJson(response);

      if (detailsResponse.status == 200 &&
          detailsResponse.results != null &&
          detailsResponse.results!.isNotEmpty) {
        _productDetailItem = detailsResponse.results![0];

        // Core details might still contain these for backward compatibility, 
        // but we'll clear them and load separately as requested.
        // Actually, let's keep them if they are there, but the user wants to split.
        // I will clear them if they come in the core API to ensure lazy loading is used.
        // _productDetailItem?.similarProducts = null;
        // _productDetailItem?.sameCategoryProducts = null;

        // Filter Similar and Same Category Products if setting is "No"
        if (_showOutOfStockProducts == "No") {
          _productDetailItem?.similarProducts
              ?.removeWhere((p) => p?.qtyStatus == "Out Of Stock");
          _productDetailItem?.sameCategoryProducts
              ?.removeWhere((p) => p?.qtyStatus == "Out Of Stock");
        }
      }
    } catch (e) {
      debugPrint("Fetch product details error: $e");
      _errorMsg = e.toString();
    } finally {
      _isDetailsLoading = false;
      _setLoading(false);
    }
  }

  Future<void> fetchSimilarProducts(String productId, {bool isLoadMore = false}) async {
    if (isLoadMore && _isSimilarLoading) return;
    if (isLoadMore && !_hasMoreSimilar) return;

    _isSimilarLoading = true;
    notifyListeners();

    if (!isLoadMore) {
      _similarProducts = null;
      _similarPage = 1;
      _hasMoreSimilar = true;
    }

    try {
      final response = await _remoteDataSource.getSimilarProducts(
        accessToken: _accessToken!,
        customerId: _customerId!,
        productId: productId,
        page: isLoadMore ? _similarPage + 1 : 1,
      );
      
      developer.log("Similar products response status: ${response['status']}", name: 'ProductDetailsDebug');

      final productsResponse = ProductsResponse.fromJson(response);
      if ((productsResponse.status == 200 || response['status']?.toString() == "200") && 
          productsResponse.results != null) {
        final List<ProductItem> fetchedSimilar =
            productsResponse.results?.whereType<ProductItem>().toList() ?? [];

        if (_showOutOfStockProducts == "No") {
          fetchedSimilar.removeWhere((p) => p.qtyStatus == "Out Of Stock");
        }

        if (fetchedSimilar.isEmpty) {
          _hasMoreSimilar = false;
        } else {
          if (isLoadMore) {
            _similarProducts ??= [];
            _similarProducts!.addAll(fetchedSimilar);
            _similarPage++;
          } else {
            _similarProducts = fetchedSimilar;
          }
        }
        developer.log("Fetched ${fetchedSimilar.length} similar products. Total loaded: ${_similarProducts?.length}", name: 'ProductDetailsDebug');
      } else {
        _hasMoreSimilar = false;
        developer.log("Failed to parse similar products or status not 200: ${productsResponse.status}", name: 'ProductDetailsDebug');
      }
    } catch (e, stackTrace) {
      developer.log("Fetch similar products error: $e", stackTrace: stackTrace, name: 'ProductDetailsDebug');
      _hasMoreSimilar = false;
    } finally {
      _isSimilarLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSameCategoryProducts(String productId, {bool isLoadMore = false}) async {
    if (isLoadMore && _isSameCategoryLoading) return;
    if (isLoadMore && !_hasMoreSameCategory) return;

    _isSameCategoryLoading = true;
    notifyListeners();

    if (!isLoadMore) {
      _sameCategoryProducts = null;
      _sameCategoryPage = 1;
      _hasMoreSameCategory = true;
    }

    try {
      final response = await _remoteDataSource.getSameCategoryProducts(
        accessToken: _accessToken!,
        customerId: _customerId!,
        productId: productId,
        page: isLoadMore ? _sameCategoryPage + 1 : 1,
      );
      
      developer.log("Same category products response status: ${response['status']}", name: 'ProductDetailsDebug');
      
      final productsResponse = ProductsResponse.fromJson(response);
      if ((productsResponse.status == 200 || response['status']?.toString() == "200") && 
          productsResponse.results != null) {
        final List<ProductItem> fetchedSameCategory =
            productsResponse.results?.whereType<ProductItem>().toList() ?? [];

        if (_showOutOfStockProducts == "No") {
          fetchedSameCategory.removeWhere((p) => p.qtyStatus == "Out Of Stock");
        }

        if (fetchedSameCategory.isEmpty) {
          _hasMoreSameCategory = false;
        } else {
          if (isLoadMore) {
            _sameCategoryProducts ??= [];
            _sameCategoryProducts!.addAll(fetchedSameCategory);
            _sameCategoryPage++;
          } else {
            _sameCategoryProducts = fetchedSameCategory;
          }
        }
        developer.log("Fetched ${fetchedSameCategory.length} same category products. Total loaded: ${_sameCategoryProducts?.length}", name: 'ProductDetailsDebug');
      } else {
        _hasMoreSameCategory = false;
        developer.log("Failed to parse same category products or status not 200: ${productsResponse.status}", name: 'ProductDetailsDebug');
      }
    } catch (e, stackTrace) {
      developer.log("Fetch same category products error: $e", stackTrace: stackTrace, name: 'ProductDetailsDebug');
      _hasMoreSameCategory = false;
    } finally {
      _isSameCategoryLoading = false;
      notifyListeners();
    }
  }

  // Selection Toggles
  void toggleDivisionSelection(int index) {
    var item = _filterProductResponse?.divisions?[index];
    if (item != null) {
      item.selected = item.selected == "Yes" ? "No" : "Yes";
      _updateCategoryIds();
      notifyListeners();
      // Android native: after toggling a category, immediately re-fetch filter
      // options with filterType="divisions" so the Suppliers + Tags lists inside
      // the open dialog update to match the selected categories.
      _filterType = "divisions";
      fetchAllFilterOptions("1");
    }
  }

  void toggleGroupSelection(int index) {
    final groups =
        _filterProductResponse?.groups ?? _filterProductResponse?.groupNames;
    var item = groups?[index];
    if (item != null) {
      item.groupSelected = item.groupSelected == "Yes" ? "No" : "Yes";
      _updateGroupIds();
      notifyListeners();

      // Follow same pattern as divisions
      _filterType = "groups";
      fetchAllFilterOptions("2");
    }
  }

  void toggleSubGroupSelection(int index) {
    var item = subGroupslist[index];
    item.groupSelected = item.groupSelected == "Yes" ? "No" : "Yes";
    _updateSubGroupIds();
    notifyListeners();

    _filterType = "subGroups";
    fetchAllFilterOptions("2");
  }

  void toggleSupplierSelection(int index) {
    var item = _filterProductResponse?.suppliers?[index];
    if (item != null) {
      item.selected = item.selected == "Yes" ? "No" : "Yes";
      _updateBrandIds();
      notifyListeners();
    }
  }

  void toggleTagSelection(int index) {
    var item = _filterProductResponse?.tags?[index];
    if (item != null) {
      item.tagSelected = item.tagSelected == "Yes" ? "No" : "Yes";
      _updateTagIds();
      notifyListeners();
    }
  }

  void onSortSelected(SortItem option) {
    // Clear all other selections
    _productSortResponse?.results?.forEach((item) {
      item?.selected = "No";
    });
    option.selected = "Yes";
    CommonMethods.sortIDs = option.value ?? "";
    fetchProducts(page: 1);
    notifyListeners();
  }

  void onFilterSubmit() {
    CommonMethods.supplierIDs = _getBrandIds();
    CommonMethods.categoryIDs = _getCategoryIds();
    CommonMethods.tagIDs = _getTagIds();
    CommonMethods.groupIDs = _getGroupIds();
    CommonMethods.subGroupIDs = _getSubGroupIds();

    _searchText = "";
    _pageCount = 1;
    fetchProducts(page: 1);
  }

  void onFilterClear() {
    CommonMethods.supplierIDs = CommonMethods.firstSuppliers;

    // FIX: Preserve Category ID if we are in Popular Category mode
    // FIX: Preserve Category ID (Always restore from firstCatIds)
    CommonMethods.categoryIDs = CommonMethods.firstCatIds;

    CommonMethods.tagIDs = CommonMethods.firstTags;

    CommonMethods.groupIDs = CommonMethods.firstGroupids;
    CommonMethods.subGroupIDs = CommonMethods.firstSubGroupids;
    CommonMethods.selecetedProducts = CommonMethods.firstSelProds;

    _searchText = "";
    _pageCount = 1;

    if (CommonMethods.productsBack == "dashboard_popcat") {
      fetchAllFilterOptionsPopular();
    } else {
      fetchAllFilterOptions("1");
    }
  }

  void onProductAvaSelected(String selection) {
    if (selection == "Show Products") {
      CommonMethods.filterSelected = "Show Products";
      onFilterClear();
    } else {
      CommonMethods.filterSelected = selection;
      CommonMethods.supplierIDs = CommonMethods.firstSuppliers;

      // FIX: Preserve Category ID if we are in Popular Category mode
      // FIX: Preserve Category ID (Always restore from firstCatIds)
      CommonMethods.categoryIDs = CommonMethods.firstCatIds;

      CommonMethods.tagIDs = CommonMethods.firstTags;

      CommonMethods.groupIDs = CommonMethods.firstGroupids;
      CommonMethods.subGroupIDs = CommonMethods.firstSubGroupids;
      CommonMethods.selecetedProducts = CommonMethods.firstSelProds;

      _searchText = "";
      _pageCount = 1;

      // Route to correct fetch method based on mode
      if (CommonMethods.productsBack == "dashboard_popcat") {
        fetchAllFilterOptionsPopular();
      } else {
        fetchAllFilterOptions("show");
      }
    }
    notifyListeners();
  }

  // Internal helper to update CommonMethods strings matching selection
  void _updateCategoryIds() {
    CommonMethods.categoryIDs = _getCategoryIds();
  }

  void _updateGroupIds() {
    CommonMethods.groupIDs = _getGroupIds();
  }

  void _updateSubGroupIds() {
    CommonMethods.subGroupIDs = _getSubGroupIds();
  }

  void _updateBrandIds() {
    CommonMethods.supplierIDs = _getBrandIds();
  }

  void _updateTagIds() {
    CommonMethods.tagIDs = _getTagIds();
  }

  String _getCategoryIds() {
    return _filterProductResponse?.divisions
            ?.where((e) => e?.selected == "Yes")
            .map((e) => e?.divisionId)
            .join(",") ??
        "";
  }

  String _getGroupIds() {
    final groups =
        _filterProductResponse?.groups ?? _filterProductResponse?.groupNames;
    return groups
            ?.where((e) => e?.groupSelected == "Yes")
            .map((e) => e?.groupId)
            .join(",") ??
        "";
  }

  String _getBrandIds() {
    return _filterProductResponse?.suppliers
            ?.where((e) => e?.selected == "Yes")
            .map((e) => e?.brandId)
            .join(",") ??
        "";
  }

  String _getSubGroupIds() {
    return subGroupslist
            .where((e) => e.groupSelected == "Yes")
            .map((e) => e.subGroupId)
            .join(",");
  }

  String _getTagIds() {
    return _filterProductResponse?.tags
            ?.where((e) => e?.tagSelected == "Yes")
            .map((e) => e?.tagId)
            .join(",") ??
        "";
  }

  // UI interaction methods
  void initViewMode(bool isTablet, ProfileResult? profile) {
    if (profile == null) return;

    String? defaultView = (isTablet
            ? profile.productsDefaultViewForBigDevices
            : profile.productsDefaultViewForSmallDevices)
        ?.toLowerCase()
        .trim();

    if (defaultView != null && defaultView.isNotEmpty) {
      if (defaultView == "grid-view") {
        _isGridView = true;
      } else if (defaultView == "table-view" || defaultView == "list-view") {
        _isGridView = false;
      } else {
        // Fallback or default
        _isGridView = false;
      }
      notifyListeners();
    }
  }

  void setGridView(bool value) {
    _isGridView = value;
    notifyListeners();
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Cart Management logic matching ProductListViewModel.kt
  Future<bool> addToCart(
      ProductItem product, String qty, String orderedAs) async {
    _setLoading(true);
    try {
      double basePrice = double.tryParse(product.price ?? "0.0") ?? 0.0;
      double basePromoPrice =
          double.tryParse(product.promotionPrice ?? "0.0") ?? 0.0;

      double calculatedPrice;
      if (orderedAs == "Carton" && product.soldAs == "Each") {
        int units = int.tryParse(product.qtyPerOuter ?? "1") ?? 1;
        calculatedPrice = (product.hasPromotion == "Yes" && basePromoPrice > 0)
            ? basePromoPrice * units
            : basePrice * units;
      } else {
        calculatedPrice = (product.hasPromotion == "Yes" && basePromoPrice > 0)
            ? basePromoPrice
            : basePrice;
      }

      final response = await _remoteDataSource.addToCart(
        accessToken: _accessToken!,
        customerId: _customerId!,
        productId: product.productId!,
        qty: qty,
        price: calculatedPrice.toStringAsFixed(2),
        orderedAs: orderedAs,
        apiData: product.apiData ?? "",
        accNum: _accountNum!,
      );

      if (response['status'] == 200) {
        await _updateCartStats(response);

        // Update local product state
        final index =
            _products.indexWhere((p) => p.productId == product.productId);
        if (index != -1) {
          _products[index] = _products[index].copyWith(
            addedToCart: "Yes",
            addedQty: qty,
            orderedAs: orderedAs,
          );
        }

        // Update Detail Item if visible
        if (_productDetailItem != null &&
            _productDetailItem?.productId == product.productId) {
          _productDetailItem = _productDetailItem!.copyDetailWith(
            addedToCart: "Yes",
            addedQty: qty,
            orderedAs: orderedAs,
          );
        }
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMsg = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updateCart(
      ProductItem product, String qty, String orderedAs) async {
    _setLoading(true);
    try {
      double basePrice = double.tryParse(product.price ?? "0.0") ?? 0.0;
      double basePromoPrice =
          double.tryParse(product.promotionPrice ?? "0.0") ?? 0.0;

      double calculatedPrice;
      if (orderedAs == "Carton" && product.soldAs == "Each") {
        int units = int.tryParse(product.qtyPerOuter ?? "1") ?? 1;
        calculatedPrice = (product.hasPromotion == "Yes" && basePromoPrice > 0)
            ? basePromoPrice * units
            : basePrice * units;
      } else {
        calculatedPrice = (product.hasPromotion == "Yes" && basePromoPrice > 0)
            ? basePromoPrice
            : basePrice;
      }

      final response = await _remoteDataSource.updateCartItem(
        accessToken: _accessToken!,
        customerId: _customerId!,
        productId: product.productId!,
        brandId: product.brandId!,
        qty: qty,
        price: calculatedPrice.toStringAsFixed(2),
        orderedAs: orderedAs,
        accNum: _accountNum!,
      );

      if (response['status'] == 200) {
        await _updateCartStats(response);

        final index =
            _products.indexWhere((p) => p.productId == product.productId);
        if (index != -1) {
          _products[index] = _products[index].copyWith(
            addedToCart: "Yes",
            addedQty: qty,
            orderedAs: orderedAs,
          );
        }

        // Update Detail Item if visible
        if (_productDetailItem != null &&
            _productDetailItem?.productId == product.productId) {
          _productDetailItem = _productDetailItem!.copyDetailWith(
            addedToCart: "Yes",
            addedQty: qty,
            orderedAs: orderedAs,
          );
        }
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _errorMsg = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<void> deleteFromCart(ProductItem product) async {
    _setLoading(true);
    try {
      final response = await _remoteDataSource.deleteCartItem(
        accessToken: _accessToken!,
        customerId: _customerId!,
        productId: product.productId!,
        brandId: product.brandId!,
      );

      if (response['status'] == 200) {
        await _updateCartStats(response);

        final index =
            _products.indexWhere((p) => p.productId == product.productId);
        if (index != -1) {
          _products[index] = _products[index].copyWith(
            addedToCart: "No",
            addedQty: "0",
            addedSubTotal: "0.000",
          );
        }

        // Update Detail Item if visible
        if (_productDetailItem != null &&
            _productDetailItem?.productId == product.productId) {
          _productDetailItem = _productDetailItem!.copyDetailWith(
            addedToCart: "No",
            addedQty: "0",
            addedSubTotal: "0.000",
          );
        }
      }
    } catch (e) {
      _errorMsg = e.toString();
    }
    _setLoading(false);
  }

  Future<void> _updateCartStats(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    CommonMethods.cartCount = response['cart_quantity']?.toString() ?? "0";
    CommonMethods.supplierCount =
        int.tryParse(response['suppliers_count']?.toString() ?? "0") ?? 0;
    CommonMethods.suppliers = response['suppliers']?.toString() ?? "";

    await prefs.setString(StorageKeys.cartCount, CommonMethods.cartCount);
    await prefs.setInt(StorageKeys.supplierCount, CommonMethods.supplierCount);
    await prefs.setString(StorageKeys.suppliers, CommonMethods.suppliers);
    notifyListeners();
  }

  void updateProductFavoriteStatus(String productId, String isFavourite) {
    // Update in list
    final index = _products.indexWhere((p) => p.productId == productId);
    if (index != -1) {
      _products[index] = _products[index].copyWith(isFavourite: isFavourite);
    }

    // Update in detail
    if (_productDetailItem != null) {
      if (_productDetailItem?.productId == productId) {
        _productDetailItem =
            _productDetailItem!.copyDetailWith(isFavourite: isFavourite);
      }

      // Update in similar products
      if (_productDetailItem!.similarProducts != null) {
        for (int i = 0; i < _productDetailItem!.similarProducts!.length; i++) {
          if (_productDetailItem!.similarProducts![i]?.productId == productId) {
            _productDetailItem!.similarProducts![i] = _productDetailItem!
                .similarProducts![i]!
                .copyWith(isFavourite: isFavourite);
          }
        }
      }

      // Update in same category products
      if (_productDetailItem!.sameCategoryProducts != null) {
        for (int i = 0;
            i < _productDetailItem!.sameCategoryProducts!.length;
            i++) {
          if (_productDetailItem!.sameCategoryProducts![i]?.productId ==
              productId) {
            _productDetailItem!.sameCategoryProducts![i] = _productDetailItem!
                .sameCategoryProducts![i]!
                .copyWith(isFavourite: isFavourite);
          }
        }
      }
    }
    notifyListeners();
  }

  // Navigation helper methods for dashboard filtering
  void clearFilters() {
    CommonMethods.resetProductFilters();
    _searchText = "";
    _activeHeaderWidget = null;
    notifyListeners();
  }

  void _syncInitialFilters() {
    CommonMethods.firstCatIds = CommonMethods.categoryIDs;
    CommonMethods.firstGroupids = CommonMethods.groupIDs;
    CommonMethods.firstSubGroupids = CommonMethods.subGroupIDs;
    CommonMethods.firstSuppliers = CommonMethods.supplierIDs;
    CommonMethods.firstSelProds = CommonMethods.selecetedProducts;
    CommonMethods.firstTags = CommonMethods.tagIDs;
  }

  void setCategory(String categoryId) {
    CommonMethods.categoryIDs = categoryId;
    _syncInitialFilters(); // Sync initial state for this mode
    CommonMethods.productsBack = "dashboard_popcat";
    fetchAllFilterOptionsPopular();
    notifyListeners();
  }

  void setSupplier(String supplierId) {
    CommonMethods.supplierIDs = supplierId;
    _syncInitialFilters(); // Sync initial state for this mode
    CommonMethods.productsBack = "suppliers";
    CommonMethods.groupIDs = "";
    CommonMethods.selecetedProducts = "";
    fetchAllFilterOptions("1");
    notifyListeners();
  }

  void setBannerNavigation({
    BannerItem? banner,
    String? productIds,
    String? divisionId,
    String? groupId,
  }) {
    clearFilters();
    CommonMethods.productsBack = "Banners";
    CommonMethods.selectFirstTime = "Yes";

    // If a banner object is passed (from DashboardScreen), extract its values
    if (banner != null) {
      productIds = banner.products;
      divisionId = banner.divisionId?.toString();
      groupId = banner.groupId?.toString();
    }

    // Apply values to CommonMethods
    if (productIds != null && productIds.isNotEmpty) {
      CommonMethods.selecetedProducts = productIds;
      CommonMethods.firstSelProds = productIds;
    } else {
      CommonMethods.selecetedProducts = "";
      CommonMethods.firstSelProds = "";
    }

    if (divisionId != null && divisionId != "0" && divisionId.isNotEmpty) {
      CommonMethods.categoryIDs = divisionId;
      CommonMethods.firstCatIds = divisionId;
    } else {
      CommonMethods.categoryIDs = "";
      CommonMethods.firstCatIds = "";
    }

    if (groupId != null && groupId != "0" && groupId.isNotEmpty) {
      CommonMethods.groupIDs = groupId;
      CommonMethods.firstGroupids = groupId;
    } else {
      CommonMethods.groupIDs = "";
      CommonMethods.firstGroupids = "";
    }

    // Reset other filters to ensure a clean slate for the Banner flow
    CommonMethods.tagIDs = "";
    CommonMethods.sortIDs = "";
    CommonMethods.supplierIDs = "";
    CommonMethods.firstSuppliers = "";
    CommonMethods.firstTags = "";
    CommonMethods.filterSelected = "Show Products";

    fetchAllFilterOptions("1");
    notifyListeners();
  }

  void setSelectedProducts(String productIds) {
    CommonMethods.selecetedProducts = productIds;
    _syncInitialFilters(); // Sync initial state
    CommonMethods.productsBack = "Banners";
    fetchAllFilterOptions("1");
    notifyListeners();
  }
}

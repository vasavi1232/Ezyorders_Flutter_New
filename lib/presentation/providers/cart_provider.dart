import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/common_methods.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/cart_models.dart';
import '../../data/models/delivery_location_response.dart';
import '../../data/models/product_models.dart';
import '../../data/models/profile_models.dart';
import 'package:collection/collection.dart';

class CartProvider extends ChangeNotifier {
  final AuthRemoteDataSource _remoteDataSource;

  CartProvider(this._remoteDataSource);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMsg;
  String? get errorMsg => _errorMsg;

  CartResponse? _cartResponse;
  CartResult? get cartResult =>
      (_cartResponse?.results != null && _cartResponse!.results!.isNotEmpty)
          ? _cartResponse!.results![0]
          : null;

  List<CartProduct> _flattenedCartItems = [];
  List<CartProduct> get flattenedCartItems => _flattenedCartItems;
  List<CartProduct> get cartItems => _flattenedCartItems;

  List<DeliveryLocationResult> _deliveryLocations = [];
  List<DeliveryLocationResult> get deliveryLocations => _deliveryLocations;

  String? _selectedDeliveryLocationId;
  String? get selectedDeliveryLocationId => _selectedDeliveryLocationId;

  // Cart Stats (Getters for UI)
  String get subTotal {
    double apiSubTotal = double.tryParse(cartResult?.subTotal ?? "0") ?? 0;
    return apiSubTotal.toStringAsFixed(CommonMethods.decimalDigits);
  }

  String get totalAmount {
    // Parity with Native Android: Use API order_amount directly.
    // The API accounts for all taxes, promo discounts, and delivery charges.
    double apiTotal = double.tryParse(cartResult?.orderAmount ?? "0") ?? 0;
    return apiTotal.toStringAsFixed(CommonMethods.decimalDigits);
  }

  String get discount =>
      double.tryParse(cartResult?.discount ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";
 
   String get promo =>
       double.tryParse(cartResult?.promo ?? "0")
           ?.toStringAsFixed(CommonMethods.decimalDigits) ??
       "0.${'0' * CommonMethods.decimalDigits}";
 
   String get deliveryCharge =>
      double.tryParse(cartResult?.deliveryCharge ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";

  String get locationDeliveryCharge =>
      double.tryParse(cartResult?.deliveryLocationCharge ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";

  String get gst =>
      double.tryParse(cartResult?.gst ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";

  String get deliveryChargeGst =>
      double.tryParse(cartResult?.deliveryChargeGst ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";

  String get taxTotal {
    double gstVal = double.tryParse(gst) ?? 0.0;
    double delGstVal = double.tryParse(deliveryChargeGst) ?? 0.0;
    return (gstVal + delGstVal).toStringAsFixed(CommonMethods.decimalDigits);
  }

  String get couponDiscount =>
      double.tryParse(cartResult?.couponDiscount ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";

  String get levy =>
      double.tryParse(cartResult?.levy ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";

  String get wet =>
      double.tryParse(cartResult?.wet ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";

  String get couponName => cartResult?.couponName ?? "";
  String get shippingSegmentHeading {
    final head = cartResult?.shippingSegmentHeading;
    if (head == null || head.trim().isEmpty) {
      return "Choose Your Delivery Location";
    }
    return CommonMethods.decodeHtmlEntities(head, stripTags: true);
  }

  String get shippingSegmentText {
    final text = cartResult?.shippingSegmentText;
    if (text == null || text.trim().isEmpty) {
      return "";
    }
    return CommonMethods.decodeHtmlEntities(text, stripTags: true);
  }

  String get subTotalHeading {
    String formatted =
        CommonMethods.formatApiLabel(cartResult?.subTotalHeading);
    if (formatted.isEmpty) {
      return CommonMethods.getTaxLabel(true,
          levy: levy, wet: wet, gst: taxTotal);
    }
    return formatted;
  }

  String get totalHeading {
    String formatted = CommonMethods.formatApiLabel(cartResult?.totalHeading);
    if (formatted.isEmpty) {
      return CommonMethods.getTaxLabel(true,
          levy: levy, wet: wet, gst: taxTotal);
    }
    return formatted;
  }

  String get suppliersExceededCharge =>
      double.tryParse(cartResult?.suppliersExceededShippingCharge ?? "0")
          ?.toStringAsFixed(CommonMethods.decimalDigits) ??
      "0.${'0' * CommonMethods.decimalDigits}";


  Future<void> init() async {
    await fetchCartDetails();
  }

  Future<void> fetchCartDetails() async {
    _isLoading = true;
    _errorMsg = null;
    debugPrint("DEBUG: fetchCartDetails started");
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? "";
      final customerId = prefs.getString(StorageKeys.userId) ?? "";

      if (accessToken.isEmpty || customerId.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _isLoading = true;
      notifyListeners();

      final response = await _remoteDataSource.getCartDetails(
          accessToken, customerId);
      debugPrint("DEBUG: getCartDetails response received: status=${response['status']}");
      _cartResponse = CartResponse.fromJson(response);

      if (_cartResponse?.status == 200) {
        _processCartData();
        
        // Android Parity: Auto-initialize delivery location from default address if not set
        if (_cartResponse?.results?.firstOrNull?.deliveryLocationId == null ||
            _cartResponse?.results?.firstOrNull?.deliveryLocationId == "0" ||
            _cartResponse?.results?.firstOrNull?.deliveryLocationId!.isEmpty == true) {
          try {
            final profileRaw = await _remoteDataSource.getProfile(accessToken, customerId);
            final profile = ProfileResponse.fromJson(profileRaw);
            final defaultAddr = profile.results?.firstOrNull?.addressesList
                ?.firstWhereOrNull((a) => a.defaultAddress == "Yes");

            if (defaultAddr != null &&
                defaultAddr.deliveryLocationId != null &&
                defaultAddr.deliveryLocationId != "0") {
              await _remoteDataSource.updateDeliveryLocation(
                accessToken: accessToken,
                customerId: customerId,
                deliveryLocationId: defaultAddr.deliveryLocationId!,
                locationDeliveryCharge: defaultAddr.deliveryLocationCharge ?? "0",
              );
              // Re-fetch cart details to get updated totals with delivery charges
              final refreshedResponse = await _remoteDataSource.getCartDetails(accessToken, customerId);
              _cartResponse = CartResponse.fromJson(refreshedResponse);
              _processCartData();
            }
          } catch (e) {
            debugPrint("Error auto-initializing delivery location: $e");
          }
        }
        
        // Sync Global Cart Count from this response
        if (response['cart_quantity'] != null) {
          final newCount = response['cart_quantity'].toString();
          CommonMethods.cartCount = newCount;
          prefs.setString(StorageKeys.cartCount, newCount);
          // Note: DashboardProvider is a separate provider, 
          // but we update CommonMethods which it reads often.
        }

        debugPrint("DEBUG: _flattenedCartItems size = ${_flattenedCartItems.length}");
        // Enrich cart items with stock info as get-cart-details doesn't provide it
        if (_flattenedCartItems.isNotEmpty) {
          try {
            final productIds = _flattenedCartItems
                .where((e) => e.productId != null)
                .map((e) => e.productId!)
                .join(",");
            
            if (productIds.isNotEmpty) {
              debugPrint("DEBUG: Requesting enrichment for products: $productIds");
              final productsResponseRaw = await _remoteDataSource.getProducts(
                accessToken: accessToken,
                customerId: customerId,
                products: productIds,
                page: 1,
              );
              
              final productsResponse = ProductsResponse.fromJson(productsResponseRaw);
              debugPrint("Cart enrichment started. Total items: ${_flattenedCartItems.length}");
              if (productsResponse.status == 200 && productsResponse.results != null) {
                debugPrint("API returned ${productsResponse.results!.length} products for enrichment");
                for (var product in _flattenedCartItems) {
                  debugPrint("Checking cart product ID: '${product.productId}'");
                  final enrichedInfo = productsResponse.results!.firstWhere(
                    (p) {
                      debugPrint("Comparing with API product ID: '${p?.productId}'");
                      return p?.productId?.trim() == product.productId?.trim();
                    },
                    orElse: () => null,
                  );
                  
                  if (enrichedInfo != null) {
                    debugPrint("SUCCESS: Enriching product ${product.productId}: qtyStatus=${enrichedInfo.qtyStatus}, allowToOrder=${enrichedInfo.allowToOrder}");
                    product.stockUnlimited = enrichedInfo.stockUnlimited;
                    product.qtyStatus = enrichedInfo.qtyStatus;
                    product.availableStockQty = enrichedInfo.availableStockQty;
                    product.allowToOrder = enrichedInfo.allowToOrder;
                  } else {
                    debugPrint("FAILURE: No enrichment info found for product ${product.productId}");
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Error enriching cart stock: $e");
          }
        }

        _selectedDeliveryLocationId = cartResult?.deliveryLocationId;
        
        // Fetch delivery locations - ISOLATED failure point
        try {
          final locResponse = await _remoteDataSource.getDeliveryLocations(
              accessToken, customerId);
          final parsedLocResponse = DeliveryLocationResponse.fromJson(locResponse);
          if (parsedLocResponse.status == 200 && parsedLocResponse.results != null) {
            _deliveryLocations = parsedLocResponse.results!.whereType<DeliveryLocationResult>().toList();
          } else {
            _deliveryLocations = [];
          }
        } catch (e) {
          debugPrint("Error fetching delivery locations (non-fatal): $e");
          // Keep cart items, but delivery locations might be missing.
        }
      } else {
        if (response['status'] == 403 && response['error'] == 'No Data') {
          _errorMsg = null;
        } else {
          _errorMsg = _cartResponse?.message;
        }
        _flattenedCartItems = [];
      }
    } catch (e) {
      debugPrint("Fatal error in fetchCartDetails: $e");
      _errorMsg = "Failed to load cart. Please try again.";
      _flattenedCartItems = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void _processCartData() {
    _flattenedCartItems = [];
    final result = cartResult;
    if (result == null || result.brands == null) return;

    // Flatten logic mirroring ShoppingCartFragment.kt
    for (var brand in result.brands!) {
      if (brand != null && brand.products != null) {
        for (var product in brand.products!) {
          if (product != null) {
            // Copy brand info into product
            product.brandId = brand.brandId;
            product.brandName = brand.brandName;
            _flattenedCartItems.add(product);
          }
        }
      }
    }
  }

  // Actions
  Future<void> updateCartItem(CartProduct item, String newQty) async {
    // Optimistic update? No, safer to wait for API as taxes/totals change complexly
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? "";
      final customerId = prefs.getString(StorageKeys.userId) ?? "";
      final accountNum = prefs.getString(StorageKeys.customerAccountNum) ?? "";

      final response = await _remoteDataSource.updateCartItem(
        accessToken: accessToken,
        customerId: customerId,
        productId: item.productId ?? "",
        brandId: item.brandId ?? "",
        qty: newQty,

        price: (double.tryParse(item.salePrice ?? "0") ?? 0) > 0
            ? item.salePrice!
            : (item.normalPrice ??
                "0"), // Uses sale_price as price, fallback to normal
        orderedAs: item.orderedAs ?? "Each",

        accNum: accountNum,
      );

      if (response['status'] == 200) {
        // Success -> Refresh Cart to get new totals
        await _updateGlobalCartStats(response);
        await fetchCartDetails();
      } else {
        _errorMsg = response['message'];
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMsg = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCartItem(CartProduct item) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? "";
      final customerId = prefs.getString(StorageKeys.userId) ?? "";

      final response = await _remoteDataSource.deleteCartItem(
        accessToken: accessToken,
        customerId: customerId,
        productId: item.productId ?? "",
        brandId: item.brandId ?? "",
      );

      if (response['status'] == 200) {
        await _updateGlobalCartStats(response);
        await fetchCartDetails();
      } else {
        _errorMsg = response['message'];
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMsg = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateGlobalCartStats(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    CommonMethods.cartCount =
        response['cart_quantity']?.toString() ?? CommonMethods.cartCount;
    CommonMethods.supplierCount =
        int.tryParse(response['suppliers_count']?.toString() ?? "0") ?? CommonMethods.supplierCount;
    CommonMethods.suppliers =
        response['suppliers']?.toString() ?? CommonMethods.suppliers;

    await prefs.setString(StorageKeys.cartCount, CommonMethods.cartCount);
  }

  Future<void> updateDeliveryLocation(String locationId, String locationCharge) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(StorageKeys.accessToken) ?? "";
      final customerId = prefs.getString(StorageKeys.userId) ?? "";

      final response = await _remoteDataSource.updateDeliveryLocation(
        accessToken: accessToken,
        customerId: customerId,
        deliveryLocationId: locationId,
        locationDeliveryCharge: locationCharge,
      );

      if (response['status'] == 200) {
        // Success -> Refresh Cart to get new totals and apply newly selected location
        await fetchCartDetails();
      } else {
        _errorMsg = response['message'];
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMsg = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

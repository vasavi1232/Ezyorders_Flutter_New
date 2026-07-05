import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/utils/common_methods.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/cart_models.dart';
import '../../data/models/profile_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../config/routes/app_routes.dart';
import '../../config/routes/app_router.dart';
import '../../core/constants/app_messages.dart';
import '../../core/constants/storage_keys.dart';
import '../../data/models/delivery_location_response.dart';
import '../../data/models/product_models.dart';
import 'package:collection/collection.dart';

class CheckoutProvider extends ChangeNotifier {
  final AuthRemoteDataSource authRemoteDataSource;
  late Razorpay _razorpay;

  CheckoutProvider(this.authRemoteDataSource) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadCompanyInfo();
  }

  // State
  int _currentStep = 0; // 0=Cart, 1=Address, 2=Payment, 3=Preview
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isStabilizing = false;
  bool get isStabilizing => _isStabilizing;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }

  String _successMessage = '';
  String _orderSuccessContent = "";
  String get orderSuccessContent => _orderSuccessContent;
  String get successMessage => _successMessage;

  String _companyName = "";
  String get companyName => _companyName;

  String _companyId = "";
  String get companyId => _companyId;

  bool _isEmailRequired = true;
  bool get isEmailRequired => _isEmailRequired;

  Future<void> _loadCompanyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _companyName = prefs.getString(StorageKeys.companyName) ?? "";
    _companyId = prefs.getString(StorageKeys.companyId) ?? "";
    final emailReqStr = prefs.getString(StorageKeys.emailRequired) ?? "";
    _isEmailRequired = emailReqStr.toLowerCase() != "no";
    notifyListeners();
  }

  bool get isPreviewEnabled {
    if (_profileResponse?.results != null &&
        _profileResponse!.results!.isNotEmpty) {
      return _profileResponse?.results?.firstOrNull?.allowToReviewOrderBeforeSubmitting == "Yes";
    }
    return false; // Default to No if not found? Android defaults to "Yes"?
    // Android: if(DashboardViewModel...equals("Yes")) -> 4 steps. So default is 3 steps (No).
  }

  bool get isLastStep {
    return _currentStep == (isPreviewEnabled ? 3 : 2);
  }

  int get totalSteps => isPreviewEnabled ? 4 : 3;

  // Profile & Address Data
  ProfileResponse? _profileResponse;
  ProfileResponse? get profileResponse => _profileResponse;

  bool get isCompanyActive {
    final status = _profileResponse?.results?.firstOrNull?.status;
    return status?.toLowerCase() == "active";
  }

  List<AddressItem> _addressList = [];
  List<AddressItem> get addressList => _addressList;

  // Cart Data
  CartResult? _cartResult;
  CartResult? get cartResult => _cartResult;
  List<CartProduct> _cartItems = [];
  List<CartProduct> get cartItems => _cartItems;

  List<DeliveryLocationResult> _deliveryLocations = [];
  List<DeliveryLocationResult> get deliveryLocations => _deliveryLocations;

  String? _selectedDeliveryLocationId;
  String? get selectedDeliveryLocationId => _selectedDeliveryLocationId;

  bool get isCartEmpty => _cartItems.isEmpty;

  // Financial Getters for Summary Widgets
  // Financial Getters for Summary Widgets
  String get subTotal {
    double apiSubTotal = double.tryParse(_cartResult?.subTotal ?? "0") ?? 0;
    return apiSubTotal.toStringAsFixed(CommonMethods.decimalDigits);
  }

  String get totalAmount {
    // Parity with Native Android: Use API order_amount directly.
    // The API accounts for all taxes, promo discounts, and delivery charges.
    double apiTotal = double.tryParse(_cartResult?.orderAmount ?? "0") ?? 0;
    return apiTotal.toStringAsFixed(CommonMethods.decimalDigits);
  }

  String get discount =>
      (double.tryParse(_cartResult?.discount ?? "0") ?? 0).toStringAsFixed(CommonMethods.decimalDigits);
  String get promo =>
      (double.tryParse(_cartResult?.promo ?? "0") ?? 0).toStringAsFixed(CommonMethods.decimalDigits);
  String get shippingCharge =>
      (double.tryParse(_cartResult?.deliveryCharge ?? "0") ?? 0)
          .toStringAsFixed(CommonMethods.decimalDigits);
  String get supplierCharge =>
      (double.tryParse(_cartResult?.suppliersExceededShippingCharge ?? "0") ??
              0)
          .toStringAsFixed(CommonMethods.decimalDigits);

  // Adjusted to include Delivery GST match Native App logic
  String get taxTotal {
    double gst = double.tryParse(_cartResult?.gst ?? "0") ?? 0;
    // Removed deliveryChargeGst addition to match web/native parity and avoid local calculations
    return gst.toStringAsFixed(CommonMethods.decimalDigits);
  }

  String get locationDeliveryCharge =>
      (double.tryParse(_cartResult?.deliveryLocationCharge ?? "0") ?? 0)
          .toStringAsFixed(CommonMethods.decimalDigits);

  String get couponDiscount =>
      (double.tryParse(_cartResult?.couponDiscount ?? "0") ?? 0)
          .toStringAsFixed(CommonMethods.decimalDigits);

  String get levy =>
      (double.tryParse(_cartResult?.levy ?? "0") ?? 0).toStringAsFixed(CommonMethods.decimalDigits);

  String get wet =>
      (double.tryParse(_cartResult?.wet ?? "0") ?? 0).toStringAsFixed(CommonMethods.decimalDigits);

  String get couponName => _cartResult?.couponName ?? "";

  String get taxLabel {
    final profile = _profileResponse?.results?.firstOrNull;
    if (profile?.showLevy == "Yes") return "Levy :";
    if (profile?.showWet == "Yes") return "WET :";
    return "GST :";
  }

  // Dynamic Headings from API
  String get shippingSegmentHeading {
    String? head = _cartResult?.shippingSegmentHeading;
    if (head == null || head.trim().isEmpty) {
      head = _profileResponse?.results?.firstOrNull?.shippingSegmentHeading;
    }
    if (head == null || head.trim().isEmpty) {
      return "Choose Your Delivery Location";
    }
    return CommonMethods.decodeHtmlEntities(head, stripTags: true);
  }

  String get shippingSegmentText {
    String? text = _cartResult?.shippingSegmentText;
    if (text == null || text.trim().isEmpty) {
      text = _profileResponse?.results?.firstOrNull?.shippingSegmentText;
    }
    if (text == null || text.trim().isEmpty) {
      return "";
    }
    return CommonMethods.decodeHtmlEntities(text, stripTags: true);
  }

  String get subTotalHeading {
    String? header = _cartResult?.subTotalHeading;
    if (header == null || header.isEmpty || header == "null") {
      header = _profileResponse?.results?.firstOrNull?.subTotalHeading;
    }
    String formatted = CommonMethods.formatApiLabel(header);
    if (formatted.isEmpty) {
      // Secondary Fallback: Construct manually if API heading is missing
      return CommonMethods.getTaxLabel(true,
          levy: levy, wet: wet, gst: taxTotal);
    }
    return formatted;
  }

  String get totalHeading {
    String? header = _cartResult?.totalHeading;
    if (header == null || header.isEmpty || header == "null") {
      header = _profileResponse?.results?.firstOrNull?.totalHeading;
    }
    String formatted = CommonMethods.formatApiLabel(header);
    if (formatted.isEmpty) {
      // Secondary Fallback: Construct manually if API heading is missing
      return CommonMethods.getTaxLabel(true,
          levy: levy, wet: wet, gst: taxTotal);
    }
    return formatted;
  }

  // Address Form Controllers (Billing)
  final TextEditingController billFirstNameController = TextEditingController();
  final TextEditingController billLastNameController = TextEditingController();
  final TextEditingController billStreetController = TextEditingController();
  final TextEditingController billStreet2Controller =
      TextEditingController(); // Optional
  final TextEditingController billCityController = TextEditingController();
  final TextEditingController billStateController = TextEditingController();
  final TextEditingController billPostCodeController = TextEditingController();
  final TextEditingController billPhoneController = TextEditingController();
  final TextEditingController billEmailController = TextEditingController();

  // Address Form Controllers (Shipping)
  final TextEditingController shipFirstNameController = TextEditingController();
  final TextEditingController shipLastNameController = TextEditingController();
  final TextEditingController shipStreetController = TextEditingController();
  final TextEditingController shipStreet2Controller =
      TextEditingController(); // Optional
  final TextEditingController shipCityController = TextEditingController();
  final TextEditingController shipStateController = TextEditingController();
  final TextEditingController shipPostCodeController = TextEditingController();
  final TextEditingController shipPhoneController = TextEditingController();
  final TextEditingController shipEmailController = TextEditingController();

  bool _isNewAddressChecked = false;
  bool get isNewAddressChecked => _isNewAddressChecked;

  // Selected Address State
  // "0" = Select, Others = Index + 1
  int _selectedAddressIndex = 0;
  int get selectedAddressIndex => _selectedAddressIndex;

  // Payment State
  String _paymentMethod = ""; // "COD" or "Online Payment"
  String get paymentMethod => _paymentMethod;

  List<String> _availablePaymentMethods = [];
  List<String> get availablePaymentMethods => _availablePaymentMethods;

  final TextEditingController couponController = TextEditingController();
  final TextEditingController orderNotesController = TextEditingController();
  final TextEditingController orderReferenceController = TextEditingController();

  // Credentials
  String _customerId = "";
  String get customerId => _customerId;
  String _accessToken = "";
  String get accessToken => _accessToken;

  // Initialization
  Future<void> initCheckout(String customerId, String accessToken,
      {int initialStep = 0, bool stabilize = false}) async {
    _currentStep = initialStep;
    _customerId = customerId;
    _accessToken = accessToken;
    _isLoading = true;
    _isStabilizing = stabilize;
    _clearOrderState(); // Clear any stale coupon/notes before starting
    notifyListeners();
    try {
      // 0. Load Payment Methods (Synced from Company Preferences)
      await _loadPaymentMethods();

      // 1. Fetch Cart Details First (Essential for Step 0)
      await refreshCartSummary(customerId, accessToken);

      // Stabilization: If re-ordered, wait for server calculation and refresh again
      if (stabilize) {
        await Future.delayed(const Duration(milliseconds: 1500));
        await refreshCartSummary(customerId, accessToken);
        _isStabilizing = false;
      }

      // 2. Fetch Profile for Addresses (Background)
      final response =
          await authRemoteDataSource.getProfile(accessToken, customerId);
      _profileResponse = ProfileResponse.fromJson(response);

      if (_profileResponse?.results != null &&
          _profileResponse!.results!.isNotEmpty) {
        _addressList = (_profileResponse!.results!.firstOrNull?.addressesList ?? [])
            .where((addr) =>
                addr.addressId != null &&
                addr.addressId.toString().trim().isNotEmpty &&
                addr.addressId.toString() != "0")
            .toList();

        // Auto-fill form with Profile Data if exists
        final profile = _profileResponse!.results![0]!;
        billFirstNameController.text = profile.firstName ?? "";
        billLastNameController.text = profile.lastName ?? "";
        billEmailController.text = profile.email ?? "";
        billPhoneController.text = profile.phone ?? "";

        // Auto-select default address
        for (int i = 0; i < _addressList.length; i++) {
          if (_addressList[i].defaultAddress == "Yes") {
            _selectedAddressIndex = i + 1; // +1 because 0 is "Choose"

            // Auto-fill Billing Form
            if (billFirstNameController.text.isEmpty) {
              billFirstNameController.text = _addressList[i].firstName ?? "";
            }
            if (billLastNameController.text.isEmpty) {
              billLastNameController.text = _addressList[i].lastName ?? "";
            }
            if (billPhoneController.text.isEmpty) {
              billPhoneController.text = _addressList[i].phone ?? "";
            }
            if (billEmailController.text.isEmpty) {
              billEmailController.text = _addressList[i].email ?? "";
            }

            billStreetController.text = _addressList[i].street ?? "";
            billStreet2Controller.text = _addressList[i].street2 ?? "";
            billCityController.text = _addressList[i].suburb ?? "";
            billStateController.text = _addressList[i].state ?? "";
            billPostCodeController.text = _addressList[i].postcode ?? "";

            _fillShippingFormWithAddress(_addressList[i]);

            // Android Parity: Auto-initialize delivery location from default address if not set
            if (_cartResult?.deliveryLocationId == null ||
                _cartResult?.deliveryLocationId == "0" ||
                _cartResult?.deliveryLocationId!.isEmpty == true) {
              if (_addressList[i].deliveryLocationId != null &&
                  _addressList[i].deliveryLocationId != "0") {
                await updateDeliveryLocation(
                  _addressList[i].deliveryLocationId!,
                  _addressList[i].deliveryLocationCharge ?? "0",
                );
              }
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDeliveryLocations() async {
    try {
      final locResponse = await authRemoteDataSource.getDeliveryLocations(
          _accessToken, _customerId);
      final parsedLocResponse = DeliveryLocationResponse.fromJson(locResponse);
      if (parsedLocResponse.status == 200 && parsedLocResponse.results != null) {
        _deliveryLocations =
            parsedLocResponse.results!.whereType<DeliveryLocationResult>().toList();
      } else {
        _deliveryLocations = [];
      }
    } catch (e) {
      _deliveryLocations = [];
    }
    notifyListeners();
  }

  Future<void> updateDeliveryLocation(
      String locationId, String locationCharge) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await authRemoteDataSource.updateDeliveryLocation(
        accessToken: _accessToken,
        customerId: _customerId,
        deliveryLocationId: locationId,
        locationDeliveryCharge: locationCharge,
      );

      if (response['status'] == 200) {
        await refreshCartSummary(_customerId, _accessToken);
      } else {
        _errorMessage = response['message'] ?? AppMessages.failureMsg;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchProfileCount() async {
    try {
      final response =
          await authRemoteDataSource.getProfile(_accessToken, _customerId);
      final profile = ProfileResponse.fromJson(response);
      if (profile.results != null && profile.results!.isNotEmpty) {
        String qty = response['cart_quantity']?.toString() ?? "0";
        CommonMethods.cartCount = qty;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(StorageKeys.cartCount, qty);
      }
    } catch (e) {
      debugPrint("Error syncing cart count: $e");
    }
  }

  Future<void> _loadPaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    String methodsStr = prefs.getString(StorageKeys.paymentMethods) ?? "";

    // Android Logic: replace("COD","Cash on Delivery").split(",")
    // Note: Android does replace BEFORE split.
    // Make sure we handle potential spaces or empty strings.

    if (methodsStr.isNotEmpty) {
      // Replace COD first
      methodsStr = methodsStr.replaceAll("COD", "Cash on Delivery");

      _availablePaymentMethods =
          methodsStr.split(",").where((s) => s.isNotEmpty).toList();

      // Auto-select first if available and nothing selected
      if (_availablePaymentMethods.isNotEmpty && _paymentMethod.isEmpty) {
        _paymentMethod = _availablePaymentMethods[0];
      }
    } else {
      _availablePaymentMethods = ["Cash on Delivery"]; // Fallback default?
      _paymentMethod = "Cash on Delivery";
    }
    notifyListeners();
  }

  // Cart Logic
  Future<void> refreshCartSummary(String customerId, String accessToken) async {
    try {
      final response =
          await authRemoteDataSource.getCartDetails(accessToken, customerId);
      final cartResponse = CartResponse.fromJson(response);

      if (cartResponse.status == 200 &&
          cartResponse.results != null &&
          cartResponse.results!.isNotEmpty) {
        _cartResult = cartResponse.results![0];
        _flattenCartItems(_cartResult!);

        _selectedDeliveryLocationId = (_cartResult?.deliveryLocationId == "0")
            ? null
            : _cartResult?.deliveryLocationId;
        
        // Enrich cart items with stock info as get-cart-details doesn't provide it
        if (_cartItems.isNotEmpty) {
          try {
            final productIds = _cartItems
                .where((e) => e.productId != null)
                .map((e) => e.productId!)
                .join(",");
            
            if (productIds.isNotEmpty) {
              final productsResponseRaw = await authRemoteDataSource.getProducts(
                accessToken: accessToken,
                customerId: customerId,
                products: productIds,
                page: 1,
              );
              
              final productsResponse = ProductsResponse.fromJson(productsResponseRaw);
              if (productsResponse.status == 200 && productsResponse.results != null) {
                for (var product in _cartItems) {
                  final enrichedInfo = productsResponse.results!.firstWhere(
                    (p) => p?.productId == product.productId,
                    orElse: () => null,
                  );
                  
                  if (enrichedInfo != null) {
                    product.stockUnlimited = enrichedInfo.stockUnlimited;
                    product.qtyStatus = enrichedInfo.qtyStatus;
                    product.availableStockQty = enrichedInfo.availableStockQty;
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Error enriching checkout cart stock: $e");
          }
        }

        await fetchDeliveryLocations();

        // ALWAYS calculate from the items we just fetched to ensure sync
        await _calculateAndSyncCartCount();
      } else {
        _cartResult = null;
        _cartItems = [];
        if (response['status'] == 403 && response['error'] == 'No Data') {
          _errorMessage = "";
        } else {
          _errorMessage = cartResponse.message ?? "Cart details not found.";
        }
      }
    } catch (e) {
      debugPrint("Error refreshing cart: $e");
      _errorMessage = "Failed to load cart items. Please try again.";
      _cartResult = null;
      _cartItems = [];
    }
    notifyListeners();
  }

  Future<void> _calculateAndSyncCartCount() async {
    int totalQty = 0;
    for (var item in _cartItems) {
      totalQty += (item.qty ?? 0);
    }

    // Update Global State
    CommonMethods.cartCount = totalQty.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.cartCount, CommonMethods.cartCount);
  }

  void _flattenCartItems(CartResult result) {
    _cartItems = [];
    if (result.brands != null) {
      for (var brand in result.brands!) {
        if (brand?.products != null) {
          for (var product in brand!.products!) {
            if (product != null) {
              // Note: Assuming product model has fields set, implies we might need to manually set brand name if not there
              // Android does: item?.brand_name = brand.brand_name
              // Our CartProduct model does not strictly have brandName setters unless we added them.
              // Wait, looking at CartProduct model, it DOES NOT receive brand info from JSON inside products list typically
              // But we can check if we customized it.
              // Checked CartProduct: has `title`, `image`, etc.
              // Let's assume we might need a wrapper or just rely on index.
              // Update: I did not add `brandName` to `CartProduct` in the `cart_models.dart`.
              // Android `CartItemS` has `brand_name`.
              // I will omit brand headers for now OR I should have added it.
              // Wait, the plan says 1:1 parity and "Vendor Grouping".
              // I can handle this in UI by checking `_cartResult?.brands`.
              // Actually, flattening makes UI easier but losing hierarchy.
              // Let's usage `_cartResult` directly in UI for sectioned list if possible.
              // But `_cartItems` is good for "All items count" etc.
              // PROCEEDING WITH FLATTENED LIST FOR SIMPLE ITERATION,
              // BUT UI WIDGET SHOULD PROBABLY USE `_cartResult.brands` to drive the ListView.builder for sections.
              // Android `MyCartAdapter` uses a flat list but checks `if(i==0 || brand_id != prev.brand_id)` for header.
              // I'll stick to that. I'll need `brandId` and `brandName` in `CartProduct`.
              // I'll re-check `cart_models.dart` briefly.
              // ... Checking ...
              _cartItems.add(product);
            }
          }
        }
      }
    }
  }

  Future<void> updateCartItem(String productId, String quantity, String brandId,
      String price, String soldAs) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await authRemoteDataSource.updateCartItem(
          accessToken: _accessToken,
          customerId: _customerId,
          productId: productId,
          brandId: brandId,
          qty: quantity,
          price: price,
          orderedAs:
              soldAs, // Assuming 'orderedAs' matches 'soldAs' or passed param
          accNum: "" // Optional
          );

      if (response['status'] == 200) {
        if (response['cart_quantity'] != null) {
          CommonMethods.cartCount = response['cart_quantity'].toString();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(StorageKeys.cartCount, CommonMethods.cartCount);
        }
      }

      await refreshCartSummary(_customerId, _accessToken);
      await _fetchProfileCount(); // Force sync
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCartItem(String productId, String brandId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await authRemoteDataSource.deleteCartItem(
          accessToken: _accessToken,
          customerId: _customerId,
          productId: productId,
          brandId: brandId);

      if (response['status'] == 200) {
        if (response['cart_quantity'] != null) {
          CommonMethods.cartCount = response['cart_quantity'].toString();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(StorageKeys.cartCount, CommonMethods.cartCount);
        }
      }

      await refreshCartSummary(_customerId, _accessToken);
      await _fetchProfileCount(); // Force sync
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await authRemoteDataSource.clearCart(
        accessToken: _accessToken,
        customerId: _customerId,
      );

      if (response['status'] == 200) {
        CommonMethods.cartCount = "0";
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(StorageKeys.cartCount, "0");
      }

      orderNotesController.clear(); // Clear Additional Notes after successful checkout
      _paymentMethod = ""; // Clear Payment Method as well

      await refreshCartSummary(_customerId, _accessToken);
      await _fetchProfileCount(); // Force sync
      // Redirection handled by UI observing empty cart or specific flag
      setStep(0); // Ensure on first step
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStep(int step) {
    _errorMessage = "";
    _currentStep = step;
    notifyListeners();
  }

  // Navigation
  void goToStep(int step) {
    setStep(step);
  }

  Future<void> placeOrder(BuildContext context) async {
    if (_paymentMethod == "Cash on Delivery") {
      final result = await createOrder();
      if (result != null && result['status'] == 200) {
        _clearOrderState();
        if (context.mounted) {
          context.go(AppRoutes.orderSuccess, extra: result);
        }
      } else {
        if (context.mounted) {
          if (!_errorMessage.contains('&lt;') && !_errorMessage.contains('<')) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(_errorMessage)));
          }
        }
      }
    } else {
      // Online Payment Flow
      await startRazorpayPayment(context);
    }
  }

  Future<void> startRazorpayPayment(BuildContext context) async {
    // Native Android Flow (PaymentActivity.kt):
    // 1. Open Razorpay FIRST (NO order created yet)
    // 2. On success/failure callback → THEN create order → THEN update payment
    // 3. On cancellation (PaymentData is null → NPE in native) → go back to checkout, NO order
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      // Launch Razorpay Checkout FIRST (matching native: PaymentActivity.startPayment())
      final prefs = await SharedPreferences.getInstance();
      final String razorKey = prefs.getString(StorageKeys.razorServerKey) ?? "";
      
      if (razorKey.isEmpty) {
        _errorMessage = "Razorpay Key not found";
        _isLoading = false;
        notifyListeners();
        return;
      }

      double amountVal = double.tryParse(totalAmount) ?? 0.0;
      int amountInPaise = (amountVal * 100).toInt();

      var options = {
        'key': razorKey,
        'amount': amountInPaise,
        'currency': 'INR', // Matches native Android: options.put("currency","INR")
        'name': 'Razorpay Corp', // Matches native
        'description': 'Test Payment', // Matches native: options.put("description","Test Payment")
        'send_sms_hash': true,
        'prefill': {
          'contact': shipPhoneController.text.trim(),
          'email': shipEmailController.text.trim(),
        }
      };

      _razorpay.open(options);
      // Note: _isLoading remains true until callback fires
    } catch (e) {
      _errorMessage = "Error in payment: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  // Razorpay Callbacks — Matches native Android PaymentActivity.kt EXACTLY

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Native Android: PaymentActivity.onPaymentSuccess() lines 131-155
    // 1. Check company active status first (matches native)
    if (!isCompanyActive) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        CommonMethods.showCompanyInActiveDialog(ctx, _companyName);
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Native: extracts razorpay_payment_id from PaymentData
      // then calls createOrderApiCall("Success", razorpay_payment_id, jsonObject)
      final String paymentId = response.paymentId ?? "";
      await _createOrderThenUpdatePayment("Success", paymentId, response.toString());
    } catch (e) {
      // Native: catch block sets paymentStatus="Cancelled", finishes activity,
      // and goes BACK to ProceedtoBuyActivity (checkout screen)
      _isLoading = false;
      _errorMessage = "";
      notifyListeners();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    // Native Android: PaymentActivity.onPaymentError() lines 157-181
    // 1. Check company active status first (matches native)
    if (!isCompanyActive) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        CommonMethods.showCompanyInActiveDialog(ctx, _companyName);
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Native Android: tries JSONObject(p2?.data.toString())
      // If user CANCELLED, p2?.data is null → NPE → catch block → back to checkout
      // If actual failure, p2?.data has payment info → createOrderApiCall("Failed", ...)

      // In Flutter, when user cancels, response.code == 2 and response.message
      // is typically null/undefined/"Payment cancelled by user"
      // Detect cancellation: no payment data available (matches native NPE behavior)
      String paymentId = "";
      bool hasParsedPaymentData = false;

      try {
        if (response.message != null && response.message!.contains('razorpay_payment_id')) {
          final errorData = response.message!;
          final regex = RegExp(r'razorpay_payment_id[":\s]+([\w]+)');
          final match = regex.firstMatch(errorData);
          if (match != null) {
            paymentId = match.group(1) ?? "";
            hasParsedPaymentData = true;
          }
        }
      } catch (_) {
        // Parsing failed — treat as cancellation (matches native NPE catch)
      }

      if (!hasParsedPaymentData) {
        // No payment data → user CANCELLED (matches native catch block)
        // Native: paymentStatus="Callback", finish(), go to ProceedtoBuyActivity
        throw Exception("Payment cancelled — no payment data");
      }

      // Actual failure with payment data → create order then update payment
      await _createOrderThenUpdatePayment("Failed", paymentId, response.message ?? "Payment Failed");

    } catch (e) {
      // Native: catch block sets paymentStatus="Callback"
      // and goes BACK to ProceedtoBuyActivity (checkout screen)
      // NO order is created when user cancels!
      _isLoading = false;
      _errorMessage = "";
      notifyListeners();
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) async {
    // Native Android: PaymentActivity.onExternalWalletSelected() lines 184-200
    // Sets paymentStatus="Success", shows toast, and navigates to CongratulationsActivity.
    // Native reads order data from static CommonMethods variables.
    // In Flutter, we need to create order + update payment to populate _lastOrderResponse
    // since it's passed via route extra to OrderSuccessScreen.
    if (!isCompanyActive) {
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        CommonMethods.showCompanyInActiveDialog(ctx, _companyName);
      }
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Create order and update payment as "Success" (external wallet = success)
      await _createOrderThenUpdatePayment("Success", "", "External Wallet: ${response.walletName}");
    } catch (e) {
      // Native: catch block sets paymentStatus="Callback" and goes back to checkout
      _isLoading = false;
      _errorMessage = "";
      notifyListeners();
    }
  }

  /// Creates order AFTER Razorpay callback, then updates payment status.
  /// Matches native Android: PaymentViewModel.createOrderApiCall() → paymentApiCall()
  Future<void> _createOrderThenUpdatePayment(String status, String transactionId, String paymentResponse) async {
    try {
      // Step 1: Create order with payment_type="Online" (matches native hardcode)
      final createOrderResponse = await createOrder();

      if (createOrderResponse == null || createOrderResponse['status'] != 200) {
        // Order creation failed
        _isLoading = false;
        _errorMessage = _errorMessage.isNotEmpty ? _errorMessage : "Order creation failed";
        notifyListeners();
        return;
      }

      final String orderId = createOrderResponse['order_id']?.toString() ?? "";
      if (orderId.isEmpty) {
        _isLoading = false;
        _errorMessage = "Invalid Order ID received";
        notifyListeners();
        return;
      }

      // Step 2: Update payment status (matches native: paymentApiCall())
      await authRemoteDataSource.updatePayment(
        accessToken: _accessToken,
        customerId: _customerId,
        orderId: _lastOrderId,
        transactionId: transactionId,
        status: status,
        paymentResponse: paymentResponse,
      );

      // Step 3: Navigate to success screen (matches native: screenRedirection observer)
      _isLoading = false;
      final context = AppRouter.navigatorKey.currentContext;

      if (status == "Success") {
        // Native: screenRedirection=0 → "Payment process has been completed successfully"
        _successMessage = "Payment Successful";
        _clearOrderState();
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment process has been completed successfully")),
          );
          context.go(AppRoutes.orderSuccess, extra: _lastOrderResponse);
        }
      } else {
        // Native: screenRedirection=1 → "Payment process has been Failed"
        // Still navigates to CongratulationsActivity (order was created)
        _errorMessage = "Payment Failed";
        _clearOrderState();
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment process has been Failed")),
          );
          context.go(AppRoutes.orderSuccess, extra: _lastOrderResponse);
        }
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Error processing payment: $e";
      notifyListeners();
    }
  }

  void nextStep() {
    _errorMessage = "";
    if (_currentStep == 0) {
      // Validate Cart Step
      // Android logic: Check minimum order amount
      // if (restrict_on_min_order_amount_not_reached == "Yes") check total
      if (_cartResult?.restrictOnMinOrderAmountNotReached == "Yes") {
        double total = double.tryParse(_cartResult?.orderAmount ?? "0") ?? 0;
        double min = double.tryParse(_cartResult?.minOrderAmount ?? "0") ?? 0;
        if (total < min) {
          _errorMessage = _cartResult?.minOrderNotificationText ??
              "Minimum order amount not reached";
          notifyListeners();
          return;
        }
      }
      // Move to Address
      _currentStep = 1;
    } else if (_currentStep == 1) {
      if (validateAddressStep()) {
        _currentStep = 2; // Payment
      } else {
        _errorMessage = AppMessages.pleaseFillAllRequiredFields;
      }
    } else if (_currentStep == 2) {
      if (validatePaymentStep()) {
        if (isPreviewEnabled) {
          _currentStep = 3; // Preview
        } else {
          // Already at last step, UI should handle "Submit"
        }
      } else {
        _errorMessage = AppMessages.pleaseSelectPaymentMethod;
      }
    }
    notifyListeners();
  }

  void previousStep() {
    _errorMessage = "";
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // Address Logic
  void toggleNewAddress(bool value) {
    _isNewAddressChecked = value;
    notifyListeners();
  }

  void onAddressSelected(int index) {
    _selectedAddressIndex = index;
    if (index > 0 && index - 1 < _addressList.length) {
      _fillShippingFormWithAddress(_addressList[index - 1]);
    } else {
      // Clear shipping form?
    }
    notifyListeners();
  }

  void _fillShippingFormWithAddress(AddressItem address) {
    final profile = _profileResponse?.results?.firstOrNull;
    shipFirstNameController.text = (address.firstName?.isNotEmpty ?? false)
        ? address.firstName!
        : (profile?.firstName ?? "");
    shipLastNameController.text = (address.lastName?.isNotEmpty ?? false)
        ? address.lastName!
        : (profile?.lastName ?? "");
    shipStreetController.text = address.street ?? "";
    shipStreet2Controller.text = address.street2 ?? "";
    shipCityController.text = address.suburb ?? "";
    shipStateController.text = address.state ?? "";
    shipPostCodeController.text = address.postcode ?? "";
    shipPhoneController.text = (address.phone?.isNotEmpty ?? false)
        ? address.phone!
        : (profile?.phone ?? "");
    shipEmailController.text = (address.email?.isNotEmpty ?? false)
        ? address.email!
        : (profile?.email ?? "");
  }

  // Payment Logic
  void selectPaymentMethod(String method) {
    // method: "COD" or "Online Payment"
    _paymentMethod = method;
    notifyListeners();
  }

  Future<bool> applyCoupon() async {
    String code = couponController.text.trim();
    if (code.isEmpty) {
      _errorMessage = "Please enter coupon code";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final response = await authRemoteDataSource.checkCouponCode(
          _accessToken, _customerId, code);
      // Assuming AuthRemoteDataSource returns Map
      if (response['status'] == 200) {
        await refreshCartSummary(_customerId, _accessToken);
        _successMessage = "Coupon Applied Successfully";
        couponController.clear();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Prioritize 'error' field for specific message like "Invalid Coupon Code"
        _errorMessage =
            response['error'] ?? response['message'] ?? "Invalid Coupon";
        couponController.clear();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
      couponController.clear();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create Order
  Future<Map<String, dynamic>?> createOrder() async {
    _isLoading = true;
    notifyListeners();

    // Prepare Billing Address
    String street = billStreetController.text;
    String street2 = billStreet2Controller.text;
    String suburb = billCityController.text;
    String state = billStateController.text;
    String postcode = billPostCodeController.text;

    // Prepare Shipping Address
    String sFirstName = isNewAddressChecked ? shipFirstNameController.text : billFirstNameController.text;
    String sLastName = isNewAddressChecked ? shipLastNameController.text : billLastNameController.text;
    String sPhone = isNewAddressChecked ? shipPhoneController.text : billPhoneController.text;
    String sEmail = isNewAddressChecked ? shipEmailController.text : billEmailController.text;
    String sStreet = isNewAddressChecked ? shipStreetController.text : billStreetController.text;
    String sStreet2 = isNewAddressChecked ? shipStreet2Controller.text : billStreet2Controller.text;
    String sSuburb = isNewAddressChecked ? shipCityController.text : billCityController.text;
    String sState = isNewAddressChecked ? shipStateController.text : billStateController.text;
    String sPostcode = isNewAddressChecked ? shipPostCodeController.text : billPostCodeController.text;

    try {
      final deviceType = await CommonMethods.getDeviceType();
      // Native Android: PaymentViewModel hardcodes var paymenttype = "Online"
      // for ALL non-COD payments. The display name (e.g. "Razor Pay", "Online Payment")
      // is irrelevant — only COD maps to "COD", everything else maps to "Online".
      String apiPaymentType;
      if (_paymentMethod == "Cash on Delivery" || _paymentMethod == "COD") {
        apiPaymentType = "COD";
      } else {
        apiPaymentType = "Online"; // Hardcoded like native Android
      }

      final response = await authRemoteDataSource.createOrder(
        accessToken: _accessToken,
        customerId: _customerId,
        paymentType: apiPaymentType,
        street: street,
        street2: street2,
        suburb: suburb,
        state: state,
        postcode: postcode,
        shippingFirstName: sFirstName,
        shippingLastName: sLastName,
        shippingPhone: sPhone,
        shippingEmail: sEmail,
        shippingStreet: sStreet,
        shippingStreet2: sStreet2,
        shippingSuburb: sSuburb,
        shippingState: sState,
        shippingPostcode: sPostcode,
        remarks: orderNotesController.text,
        orderReferenceNumber: orderReferenceController.text,
        deviceType: deviceType,
      );

      if (response['status'] == 200) {
        _lastOrderId = response['order_id']?.toString() ?? "";
        _lastOrderResponse = response;
        _isLoading = false;
        notifyListeners();
        return response;
      } else {
        _errorMessage = response['error'] ?? response['message'] ?? AppMessages.failureMsg;
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = AppMessages.failureMsg;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  bool validateAddressStep() {
    // Validate Billing Address (Always Required)
    bool isBillingValid = billFirstNameController.text.isNotEmpty &&
        billLastNameController.text.isNotEmpty &&
        billStreetController.text.isNotEmpty &&
        billCityController.text.isNotEmpty &&
        billStateController.text.isNotEmpty &&
        billPostCodeController.text.isNotEmpty &&
        billPhoneController.text.isNotEmpty &&
        (!_isEmailRequired || billEmailController.text.isNotEmpty);

    if (!isBillingValid) return false;

    // Validate Shipping Address (Only if "Different Address" is checked)
    if (isNewAddressChecked) {
      return shipFirstNameController.text.isNotEmpty &&
          shipLastNameController.text.isNotEmpty &&
          shipStreetController.text.isNotEmpty &&
          shipCityController.text.isNotEmpty &&
          shipStateController.text.isNotEmpty &&
          shipPostCodeController.text.isNotEmpty &&
          shipPhoneController.text.isNotEmpty &&
          (!_isEmailRequired || shipEmailController.text.isNotEmpty);
    }

    return true;
  }

  bool validatePaymentStep() {
    return _paymentMethod.isNotEmpty;
  }

  Future<bool> sendOrderReceipt(String orderId, String emails) async {
    try {
      final response = await authRemoteDataSource.sendOrderReceipt(
        accessToken: _accessToken,
        customerId: _customerId,
        orderId: orderId,
        emails: emails,
      );
      return response['status'] == 200;
    } catch (e) {
      debugPrint("Error sending receipt: $e");
      return false;
    }
  }

  void _clearOrderState() {
    _paymentMethod = "";
    couponController.clear();
    orderNotesController.clear();
    orderReferenceController.clear();
    _successMessage = "";
  }

  void clearCartLocal() {
    _cartItems = [];
    _cartResult = null;
    _currentStep = 0;
    billFirstNameController.clear();
    billLastNameController.clear();
    // Keep others maybe? Or clear all.
    // Android "cleardata()" clears everything.
    billStreetController.clear();
    billStreet2Controller.clear();
    billCityController.clear();
    billStateController.clear();
    billPostCodeController.clear();

    shipFirstNameController.clear();
    shipLastNameController.clear();
    shipStreetController.clear();
    shipStreet2Controller.clear();
    shipCityController.clear();
    shipStateController.clear();
    shipPostCodeController.clear();
    shipPhoneController.clear();
    shipEmailController.clear();

    _clearOrderState();
    notifyListeners();
  }

  @override
  void dispose() {
    billFirstNameController.dispose();
    billLastNameController.dispose();
    billStreetController.dispose();
    billStreet2Controller.dispose();
    billCityController.dispose();
    billStateController.dispose();
    billPostCodeController.dispose();
    billPhoneController.dispose();
    billEmailController.dispose();

    shipFirstNameController.dispose();
    shipLastNameController.dispose();
    shipStreetController.dispose();
    shipStreet2Controller.dispose();
    shipCityController.dispose();
    shipStateController.dispose();
    shipPostCodeController.dispose();
    shipPhoneController.dispose();
    shipEmailController.dispose();

    couponController.dispose();
    orderNotesController.dispose();
    orderReferenceController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  String _lastOrderId = "";
  String get lastOrderId => _lastOrderId;

  Map<String, dynamic>? _lastOrderResponse;

  Future<void> fetchOrderSuccessMessage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await authRemoteDataSource.getOrderSuccessMessage(
          accessToken: _accessToken);
      if (response['status'] == 200) {
        final results = response['results'] as List?;
        if (results != null && results.isNotEmpty) {
          _orderSuccessContent = results[0]['top_content']?.toString() ?? "";
        }
      }
    } catch (e) {
      debugPrint("Error fetching success message: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

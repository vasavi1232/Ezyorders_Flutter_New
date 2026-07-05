import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/companies_response.dart';
import '../../core/constants/url_api_key.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  Future<UserEntity> login(String email, String password) async {
    // Note: Android uses FormUrlEncoded. http.post with map body does this by default.
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}${ApiEndpoints.login}",
      body: {
        'user_name': email,
        'password': password,
      },
    );

    try {
      if (response is String) {
        apiClient.logger.e('login response is a String, but Map was expected. Response body: "$response"');
        throw FormatException('Response is not a valid JSON object: $response');
      }
      return UserEntity.fromJson(response);
    } catch (e, stackTrace) {
      apiClient.logger.e('Model parsing error in login', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<UserEntity> signUp({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String receiptEmails,
    required String title,
    String customerSource = "Android",
    String deviceType = "Android",
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}${ApiEndpoints.signUp}",
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'email': email,
        'password': password,
        'orders_receipt_emails': receiptEmails,
        'title': title,
        'customer_source': customerSource,
        'device_type': deviceType,
        'browser_type': '',
        'ip_address': '',
      },
    );

    try {
      if (response is String) {
        apiClient.logger.e('signUp response is a String, but Map was expected. Response body: "$response"');
        throw FormatException('Response is not a valid JSON object: $response');
      }
      return UserEntity.fromJson(response);
    } catch (e, stackTrace) {
      apiClient.logger.e('Model parsing error in signUp', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<CompaniesResponse> getCompanies() async {
    // Companies List uses COMPANYMAIN_URL + "companies-list.php?" (Assuming endpoint is relative)
    // In Android: mainclient.create(BackEndApi::class.java).getCompaniesList()
    // mainclient uses UrlApiKey.COMPANYMAIN_URL
    final response = await apiClient.get(
      "${UrlApiKey.companyMainUrl}${ApiEndpoints.companiesList}",
    );
    return CompaniesResponse.fromJson(response);
  }

  Future<dynamic> forgotPassword(String email) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}forgot-password",
      body: {
        'forgot_email': email,
      },
    );
    // Return raw response for provider to parse status
    return response;
  }

  Future<Map<String, dynamic>> getOrderHistory({
    required String accessToken,
    required String customerId,
    required int page,
    String? searchText,
    String? startDate,
    String? endDate,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}order-history",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
        'search_text': searchText ?? "",
        'start_date': startDate ?? "",
        'end_date': endDate ?? "",
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getOrderDetails({
    required String accessToken,
    required String customerId,
    required String orderId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}order-details",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'order_id': orderId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> deleteOrder({
    required String accessToken,
    required String customerId,
    required String orderId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}delete-order",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'order_id': orderId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> duplicateOrder({
    required String accessToken,
    required String customerId,
    required String oldOrderId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}duplicate-order",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'old_order_id': oldOrderId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> reorderOrder({
    required String accessToken,
    required String customerId,
    required String oldOrderId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}re-order",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'old_order_id': oldOrderId,
      },
    );
    return response;
  }

  // Dashboard APIs
  Future<Map<String, dynamic>> getProfile(
      String accessToken, String customerId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}get-profile",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> closeAccountMessage({
    required String accessToken,
    required String customerId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}close-account-message",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> closeAccount({
    required String accessToken,
    required String customerId,
    required String reason,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}close-account",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'account_deleted_reason': reason,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getBanners(String accessToken) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}banners",
      body: {
        'access_token': accessToken,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getFooterBanners(String accessToken) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}footer-banners",
      body: {
        'access_token': accessToken,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getHomePageBlocks(String accessToken) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}home-page-blocks",
      body: {
        'access_token': accessToken,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getPromotions(
      String accessToken, String customerId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}promotions",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getBestSellers(
      String accessToken, String customerId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}best-sellers",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getFlashDeals(
      String accessToken, String customerId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}flash-deals",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getNewArrivals(
      String accessToken, String customerId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}new-arrivals",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getHotSelling(
      String accessToken, String customerId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}hot-selling",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getPopularCategories(
      String accessToken, String customerId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}popular-categories",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getSupplierLogos(
      String accessToken, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}supplier-logos",
      body: {
        'access_token': accessToken,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getRecentlyAdded(
      String accessToken, String customerId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}recently-added",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getPopularAdvertisements(
      String accessToken, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}product-advertisements",
      body: {
        'access_token': accessToken,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getWishlistCategories(
      String accessToken, String customerId, String productId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}wishlist-categories",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'product_id': productId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> addToWishlist({
    required String accessToken,
    required String customerId,
    required String productId,
    required String categoryName,
    required String categoryIds,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}add-to-wishlist",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'product_id': productId,
        'category_name': categoryName,
        'category_id': categoryIds,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> addToCart({
    required String accessToken,
    required String customerId,
    required String productId,
    required String qty,
    required String price,
    required String orderedAs,
    required String apiData,
    String accNum = "",
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}add-to-cart",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'product_id': productId,
        'qty': qty,
        'price': price,
        'ordered_as': orderedAs,
        'acc_num': accNum,
        'api_data': apiData,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> updateCartItem({
    required String accessToken,
    required String customerId,
    required String productId,
    required String brandId,
    required String qty,
    required String price,
    required String orderedAs,
    String accNum = "",
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}update-cart-item",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'product_id': productId,
        'brand_id': brandId,
        'qty': qty,
        'price': price,
        'ordered_as': orderedAs,
        'acc_num': accNum,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> deleteCartItem({
    required String accessToken,
    required String customerId,
    required String productId,
    required String brandId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}delete-cart-item",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'product_id': productId,
        'brand_id': brandId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> deleteFromWishlist({
    required String accessToken,
    required String customerId,
    required String wishlistId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}delete-from-wishlist",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'wishlist_id': wishlistId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> clearCart({
    required String accessToken,
    required String customerId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}clear-cart",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
      },
    );
    return response;
  }



  Future<Map<String, dynamic>> getGlobalWishlistCategories(
      String accessToken, String customerId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}wishlist-categories",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
      },
    );
    return response;
  }

  // Drawer APIs
  Future<Map<String, dynamic>> getAboutUs(String accessToken) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}about-us",
      body: {
        'access_token': accessToken,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> sendFeedback({
    required String name,
    required String email,
    required String subject,
    required String message,
    required String phone,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}contact-us",
      body: {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'phone': phone,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getFAQCategories(String accessToken) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}faq-categories",
      body: {
        'access_token': accessToken,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getFAQDetails(
      String accessToken, String categoryId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}faq",
      body: {
        'access_token': accessToken,
        'category_id': categoryId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getNotifications(
      String accessToken, String customerId, int page) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}notifications",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> changeNotificationStatus(
      String accessToken, String customerId, String notificationId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}change-notification-status",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'notification_id': notificationId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> deleteNotification(
      String accessToken, String customerId, String notificationId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}delete-notification",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'notification_id': notificationId,
      },
    );
    return response;
  }

  // Product List APIs
  Future<Map<String, dynamic>> getProducts({
    required String accessToken,
    required String customerId,
    String brandId = "",
    String divisionId = "",
    String groupId = "",
    String subGroupId = "",
    String subSubGroupId = "",
    required int page,
    String orderby = "",
    String tagId = "",
    String productsType = "",
    String searchText = "",
    String products = "",
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}products",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'brand_id': brandId,
        'division_id': divisionId,
        'group_id': groupId,
        'sub_group_id': subGroupId,
        'sub_sub_group_id': subSubGroupId,
        'page': page.toString(),
        'orderby': orderby,
        'tag_id': tagId,
        'products_type': productsType,
        'search_text': searchText,
        'products': products,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getAllFilterProducts({
    required String accessToken,
    required String customerId,
    String divisionId = "",
    String brandId = "",
    String selectedBrands = "",
    String groupId = "",
    String subGroupId = "",
    String subSubGroupId = "",
    String selectedProducts = "",
    String selectedDivisions = "",
    String selectedGroups = "",
    String selectedSubGroups = "",
    String selectedSubSubGroups = "",
    String productsType = "All Products",
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}product-filters",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'division_id': divisionId,
        'brand_id': brandId,
        'selected_brands': selectedBrands,
        'group_id': groupId,
        'sub_group_id': subGroupId,
        'sub_sub_group_id': subSubGroupId,
        'selected_products': selectedProducts,
        'selected_divisions': selectedDivisions,
        'selected_groups': selectedGroups,
        'selected_sub_groups': selectedSubGroups,
        'selected_sub_sub_groups': selectedSubSubGroups,
        'products_type': productsType,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getProductSortOptions(
      String accessToken, String customerId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}product-sort-options",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getProductDetails(
      String accessToken, String customerId, String productId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}product-details",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'product_id': productId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getSimilarProducts({
    required String accessToken,
    required String customerId,
    required String productId,
    int page = 1,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}similar-products",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'product_id': productId,
        'page': page.toString(),
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getSameCategoryProducts({
    required String accessToken,
    required String customerId,
    required String productId,
    int page = 1,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}same-category-products",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'product_id': productId,
        'page': page.toString(),
      },
    );
    return response;
  }

  // Cart Details
  Future<Map<String, dynamic>> getCartDetails(
      String accessToken, String customerId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}cart-details",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
      },
    );
    return response;
  }

  // Checkout APIs
  Future<Map<String, dynamic>> getDeliveryLocations(
      String accessToken, String customerId) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}delivery-locations",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> checkCouponCode(
      String accessToken, String customerId, String couponCode) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}check-coupon-code",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'coupon_code': couponCode,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> updateDeliveryLocation({
    required String accessToken,
    required String customerId,
    required String deliveryLocationId,
    required String locationDeliveryCharge,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}update-delivery-location",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'delivery_location_id': deliveryLocationId,
        'location_delivery_charge': locationDeliveryCharge,
      },
    );
    return response;
  }

  // Create Order - The Massive one
  Future<Map<String, dynamic>> createOrder({
    required String accessToken,
    required String customerId,
    required String paymentType,
    required String street,
    required String street2,
    required String suburb,
    required String state,
    required String postcode,
    required String shippingFirstName,
    required String shippingLastName,
    required String shippingPhone,
    required String shippingEmail,
    required String shippingStreet,
    required String shippingStreet2,
    required String shippingSuburb,
    required String shippingState,
    required String shippingPostcode,
    required String remarks,
    String orderReferenceNumber = "",
    String customerSource = "Android",
    String deviceType = "Android",
    String browserType = "",
    String ipAddress = "",
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}create-order",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'payment_type': paymentType,
        'street': street,
        'street2': street2,
        'suburb': suburb,
        'state': state,
        'postcode': postcode,
        'shipping_first_name': shippingFirstName,
        'shipping_last_name': shippingLastName,
        'shipping_phone': shippingPhone,
        'shipping_email': shippingEmail,
        'shipping_street': shippingStreet,
        'shipping_street2': shippingStreet2,
        'shipping_suburb': shippingSuburb,
        'shipping_state': shippingState,
        'shipping_postcode': shippingPostcode,
        'remarks': remarks,
        'order_reference_number': orderReferenceNumber,
        'order_source': customerSource,
        'device_type': Platform.operatingSystem, // Uses dart:io
        'browser_type': browserType,
        'ip_address': ipAddress,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> updatePayment({
    required String accessToken,
    required String customerId,
    required String orderId,
    required String transactionId,
    required String status,
    required String paymentResponse,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}order-payment",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'order_id': orderId,
        'transaction_id': transactionId,
        'status': status,
        'payment_response': paymentResponse,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> editProfile({
    required String accessToken,
    required String customerId,
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
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}edit-profile",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'first_name': firstName,
        'last_name': lastName,
        'phone': mobile,
        'email': email,
        'street': street,
        'street2': street2,
        'suburb': suburb,
        'state': state,
        'postcode': postcode,
      },
    );
    if (response is String) return {'status': 0, 'message': 'Server error'};
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> editProfileImage({
    required String accessToken,
    required String customerId,
    required String firstName,
    required String lastName,
    required String mobile,
    required String email,
    required String street,
    required String street2,
    required String suburb,
    required String state,
    required String postcode,
    required String imageName,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}edit-profile",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'first_name': firstName,
        'last_name': lastName,
        'phone': mobile,
        'email': email,
        'street': street,
        'street2': street2,
        'suburb': suburb,
        'state': state,
        'postcode': postcode,
        'photo': imageName,
      },
    );
    if (response is String) return {'status': 0, 'message': 'Server error'};
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> imageFileUpload(
      File file, String accessToken, String customerId) async {
    // Note: This requires 'package:http/http.dart' as http import
    var request = http.MultipartRequest(
        "POST", Uri.parse("${UrlApiKey.baseUrl}upload-profile-photo"));
    request.fields['access_token'] = accessToken;
    request.fields['customer_id'] = customerId;

    var pic = await http.MultipartFile.fromPath("uploaded_file", file.path);
    request.files.add(pic);

    var response = await request.send();
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(responseString);
      } catch (e) {
        debugPrint("JSON Decode Error: $e\nResponse: $responseString");
        return {
          'status': 0,
          'message': 'Server returned invalid format. Please try again later.'
        };
      }
    } else {
      throw const FormatException("File upload failed");
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String accessToken,
    required String customerId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}change-password",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'new_password': newPassword,
      },
    );
    return response;
  }

  // Address Book APIs
  Future<Map<String, dynamic>> addAddress({
    required String accessToken,
    required String customerId,
    required String firstName,
    required String lastName,
    required String mobile,
    required String email,
    required String street,
    required String street2,
    required String suburb,
    required String state,
    required String postcode,
    required String defaultAddress,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}add-address",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'first_name': firstName,
        'last_name': lastName,
        'phone': mobile, // Android maps mobile -> phone param usually
        'email': email,
        'street': street,
        'street2': street2,
        'suburb': suburb,
        'state': state,
        'postcode': postcode,
        'default_address': defaultAddress,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> editAddressBook({
    required String accessToken,
    required String customerId,
    required String addressId,
    required String firstName,
    required String lastName,
    required String mobile,
    required String email,
    required String street,
    required String street2,
    required String suburb,
    required String state,
    required String postcode,
    required String defaultAddress,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}edit-address",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'address_id': addressId,
        'first_name': firstName,
        'last_name': lastName,
        'phone': mobile,
        'email': email,
        'street': street,
        'street2': street2,
        'suburb': suburb,
        'state': state,
        'postcode': postcode,
        'default_address': defaultAddress,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> deleteAddress({
    required String accessToken,
    required String customerId,
    required String addressId,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}delete-address",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'address_id': addressId,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> sendOrderReceipt({
    required String accessToken,
    required String customerId,
    required String orderId,
    required String emails,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}send-order-receipt-email",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'order_id': orderId,
        'email': emails,
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    } else {
      // If server returns HTML or other non-JSON, wrap it or throw
      return {'status': 0, 'message': 'Invalid server response'};
    }
  }

  Future<Map<String, dynamic>> scanProduct({
    required String accessToken,
    required String customerId,
    required String barcode,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}scan-product",
      body: {
        'access_token': accessToken,
        'customer_id': customerId,
        'barcode': barcode,
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> getOrderSuccessMessage({
    required String accessToken,
  }) async {
    final response = await apiClient.post(
      "${UrlApiKey.baseUrl}order-success",
      body: {
        'access_token': accessToken,
      },
    );
    return response;
  }
}

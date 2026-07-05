class ProfileResponse {
  int? status;
  String? message;
  List<ProfileResult?>? results;
  int? resultsCount;
  String? cartQuantity;
  String? suppliersCount;
  String? suppliers;

  ProfileResponse({
    this.status,
    this.message,
    this.results,
    this.resultsCount,
    this.cartQuantity,
    this.suppliersCount,
    this.suppliers,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      status: json['status'],
      message: json['message'],
      results: json['results'] != null
          ? (json['results'] as List)
          .map((i) => i != null ? ProfileResult.fromJson(i) : null)
          .toList()
          : null,
      resultsCount: json['results_count'],
      cartQuantity: json['cart_quantity']?.toString(),
      suppliersCount: json['suppliers_count']?.toString(),
      suppliers: json['suppliers']?.toString(),
    );
  }
}

class ProfileResult {
  String? customerId;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? mobile;
  String? street;
  String? street2;
  String? suburb;
  String? state;
  String? postcode;
  String? image;
  String? unreadNotificationsCount;
  String? wishlistPageHeading;
  String? status;
  String? showPortalIn;
  String? accNum;
  String? allowScanToOrder;
  String? priceDisplayTypeDecimals;
  String? priceDisplayType;
  String? supplierLogosPosition;
  String? freeShippingForUnlimitedSupplierProducts;
  String? maximumNumberOfSuppliersProductsForFreeShipping;
  String? showMarqueText;
  String? marqueText;
  String? marqueTextColor;
  String? marqueTextSize;
  String? marqueTextBackgroundColor;
  String? marqueTextFormat;
  String? bestSellers;
  String? productsAdvertisements;
  String? hotSelling;
  String? supplierLogos;
  String? popularCategories;
  String? flashDeals;
  String? newArrivals;
  String? recentlyAdded;
  String? showPriceIncludingGst;
  String? subTotalHeadingForOrderHistory;
  String? customerMessageForAdditionalSuppliersCharge;
  String? showShippingSegment;
  String? showSoldAs;
  String? allowCartonLevelPurchaseOfEach;
  String? companyMobile;
  String? companyEmail;
  String? companyStreet;
  String? companySuburb;
  String? companyState;
  String? companyPostcode;
  List<dynamic>? wishlist;
  int? wishlistCount;
  String? allowToReviewOrderBeforeSubmitting;
  String? customerLoginLogo;
  String? subTotalHeading;
  String? totalHeading;
  String? allowCustomerToCancelOrder;
  String? allowCustomersToReplicateOrders;
  String? allowCustomerToReorderSameProducts;
  String? showSupplierStatus;
  String? showLevy;
  String? showWet;
  String? includeLevyInPriceCalculation;
  String? includeWetInPriceCalculation;
  String? allowCustomersToAddWishlist;
  String? replicateOrderConfirmationText;
  String? reorderConfirmationText;
  String? restrictOnMinOrderAmountNotReached;
  String? minimumOrderAmount;
  String? minOrderNotificationText;
  String? restrictOnMaxOrderAmountReached;
  String? maxOrderAmount;
  String? maxOrderNotificationText;
  String? maxOrderUnlimited;
  String? allowNewUserSignUp;
  String? emailRequiredForCustomerSignup;
  String? showPromo;
  String? shippingSegmentHeading;
  String? shippingSegmentText;
  String? storeNotAvailable;
  String? storeNotAvailableReason;
  String? productsDefaultViewForSmallDevices;
  String? productsDefaultViewForBigDevices;
  String? showSpecialIdDescription;
  String? showOutOfStockProducts;
  String? priceIncludesGstMessage;
  String? priceExcludesGstMessage;
  String? showGstInCart;
  String? productImageDimensions;
  List<AddressItem>? addressesList;

  ProfileResult({
    this.customerId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.mobile,
    this.street,
    this.street2,
    this.suburb,
    this.state,
    this.postcode,
    this.image,
    this.unreadNotificationsCount,
    this.wishlistPageHeading,
    this.status,
    this.showPortalIn,
    this.accNum,
    this.allowScanToOrder,
    this.priceDisplayTypeDecimals,
    this.priceDisplayType,
    this.supplierLogosPosition,
    this.freeShippingForUnlimitedSupplierProducts,
    this.maximumNumberOfSuppliersProductsForFreeShipping,
    this.showMarqueText,
    this.marqueText,
    this.marqueTextColor,
    this.marqueTextSize,
    this.marqueTextBackgroundColor,
    this.marqueTextFormat,
    this.bestSellers,
    this.productsAdvertisements,
    this.hotSelling,
    this.supplierLogos,
    this.popularCategories,
    this.flashDeals,
    this.newArrivals,
    this.recentlyAdded,
    this.showPriceIncludingGst,
    this.subTotalHeadingForOrderHistory,
    this.customerMessageForAdditionalSuppliersCharge,
    this.showShippingSegment,
    this.showSoldAs,
    this.allowCartonLevelPurchaseOfEach,
    this.companyMobile,
    this.companyEmail,
    this.companyStreet,
    this.companySuburb,
    this.companyState,
    this.companyPostcode,
    this.wishlist,
    this.wishlistCount,
    this.allowToReviewOrderBeforeSubmitting,
    this.customerLoginLogo,
    this.subTotalHeading,
    this.totalHeading,
    this.allowCustomerToCancelOrder,
    this.allowCustomersToReplicateOrders,
    this.allowCustomerToReorderSameProducts,
    this.showSupplierStatus,
    this.showLevy,
    this.showWet,
    this.includeLevyInPriceCalculation,
    this.includeWetInPriceCalculation,
    this.allowCustomersToAddWishlist,
    this.replicateOrderConfirmationText,
    this.reorderConfirmationText,
    this.restrictOnMinOrderAmountNotReached,
    this.minimumOrderAmount,
    this.minOrderNotificationText,
    this.restrictOnMaxOrderAmountReached,
    this.maxOrderAmount,
    this.maxOrderNotificationText,
    this.maxOrderUnlimited,
    this.allowNewUserSignUp,
    this.emailRequiredForCustomerSignup,
    this.showPromo,
    this.shippingSegmentHeading,
    this.shippingSegmentText,
    this.storeNotAvailable,
    this.storeNotAvailableReason,
    this.productsDefaultViewForSmallDevices,
    this.productsDefaultViewForBigDevices,
    this.showSpecialIdDescription,
    this.showOutOfStockProducts,
    this.priceIncludesGstMessage,
    this.priceExcludesGstMessage,
    this.showGstInCart,
    this.productImageDimensions,
    this.addressesList,
  });

  factory ProfileResult.fromJson(Map<String, dynamic> json) {
    return ProfileResult(
      customerId: json['customer_id']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      mobile: json['mobile']?.toString(),
      street: json['street']?.toString(),
      street2: json['street2']?.toString(),
      suburb: json['suburb']?.toString(),
      state: json['state']?.toString(),
      postcode: json['postcode']?.toString(),
      image: json['image']?.toString(),
      unreadNotificationsCount: json['unread_notifications_count']?.toString(),
      wishlistPageHeading: json['wishlist_page_heading']?.toString(),
      status: json['status']?.toString(),
      showPortalIn: json['show_portal_in']?.toString(),
      accNum: json['acc_num']?.toString(),
      allowScanToOrder: json['allow_scan_to_order']?.toString(),
      priceDisplayTypeDecimals: json['price_display_type_decimals']?.toString(),
      priceDisplayType: json['price_display_type']?.toString(),
      supplierLogosPosition: json['supplier_logos_position']?.toString(),
      freeShippingForUnlimitedSupplierProducts:
      json['free_shipping_for_unlimited_supplier_products']?.toString(),
      maximumNumberOfSuppliersProductsForFreeShipping:
      json['maximum_number_of_suppliers_products_for_free_shipping']
          ?.toString(),
      showMarqueText: json['show_marque_text']?.toString(),
      marqueText: json['marque_text']?.toString(),
      marqueTextColor: json['marque_text_color']?.toString(),
      marqueTextSize: json['marque_text_size']?.toString(),
      marqueTextBackgroundColor:
      json['marque_text_background_color']?.toString(),
      marqueTextFormat: json['marque_text_format']?.toString(),
      bestSellers: json['best_sellers']?.toString(),
      productsAdvertisements: json['products_advertisements']?.toString(),
      hotSelling: json['hot_selling']?.toString(),
      supplierLogos: json['supplier_logos']?.toString(),
      popularCategories: json['popular_categories']?.toString(),
      flashDeals: json['flash_deals']?.toString(),
      newArrivals: json['new_arrivals']?.toString(),
      recentlyAdded: json['recently_added']?.toString(),
      showPriceIncludingGst: json['show_price_including_gst']?.toString(),
      subTotalHeadingForOrderHistory: json['sub_total_heading_for_order_history']?.toString(),
      customerMessageForAdditionalSuppliersCharge:
      json['customer_message_for_additional_suppliers_charge']?.toString(),
      showShippingSegment: json['show_shipping_segment']?.toString(),
      showSoldAs: json['show_sold_as']?.toString(),
      allowCartonLevelPurchaseOfEach:
      json['allow_carton_level_purchase_of_each']?.toString(),
      companyMobile: json['company_mobile']?.toString(),
      companyEmail: json['company_email']?.toString(),
      companyStreet: json['company_street']?.toString(),
      companySuburb: json['company_suburb']?.toString(),
      companyState: json['company_state']?.toString(),
      companyPostcode: json['company_postcode']?.toString(),
      wishlist: json['wishlist'] as List?,
      wishlistCount: json['wishlist_count'] is int ? json['wishlist_count'] : int.tryParse(json['wishlist_count']?.toString() ?? "0"),
      allowToReviewOrderBeforeSubmitting:
      json['allow_to_review_order_before_submmitting']?.toString() ?? json['allow_to_review_order_before_submitting']?.toString(),
      customerLoginLogo: json['customer_login_logo']?.toString(),
      subTotalHeading: json['sub_total_heading']?.toString(),
      totalHeading: json['total_heading']?.toString(),
      allowCustomerToCancelOrder: json['allow_customer_to_cancel_order']?.toString(),
      allowCustomersToReplicateOrders: json['allow_customers_to_replicate_orders']?.toString(),
      allowCustomerToReorderSameProducts: json['allow_customer_to_reorder_same_products']?.toString(),
      showSupplierStatus: json['show_supplier_status']?.toString(),
      showLevy: json['show_levy']?.toString(),
      showWet: json['show_wet']?.toString(),
      includeLevyInPriceCalculation: json['include_levy_in_price_calculation']?.toString(),
      includeWetInPriceCalculation: json['include_wet_in_price_calculation']?.toString(),
      allowCustomersToAddWishlist: json['allow_customers_to_add_wishlist']?.toString(),
      replicateOrderConfirmationText: json['replicate_order_confirmation_text']?.toString(),
      reorderConfirmationText: json['reorder_confirmation_text']?.toString(),
      restrictOnMinOrderAmountNotReached: json['restrict_on_min_order_amount_not_reached']?.toString(),
      minimumOrderAmount: json['minimum_order_amount']?.toString(),
      minOrderNotificationText: json['min_order_notification_text']?.toString(),
      restrictOnMaxOrderAmountReached: json['restrict_on_max_order_amount_reached']?.toString(),
      maxOrderAmount: json['max_order_amount']?.toString(),
      maxOrderNotificationText: json['max_order_notification_text']?.toString(),
      maxOrderUnlimited: json['max_order_unlimited']?.toString(),
      allowNewUserSignUp: json['allow_new_user_sign_up']?.toString(),
      emailRequiredForCustomerSignup: json['email_required_for_customer_signup']?.toString(),
      showPromo: json['show_promo']?.toString(),
      shippingSegmentHeading: json['shipping_segment_heading']?.toString(),
      shippingSegmentText: json['shipping_segment_text']?.toString(),
      storeNotAvailable: json['store_not_available']?.toString(),
      storeNotAvailableReason: json['store_not_available_reason']?.toString(),
      productsDefaultViewForSmallDevices: json['products_default_view_for_small_devices']?.toString(),
      productsDefaultViewForBigDevices: json['products_default_view_for_big_devices']?.toString(),
      showSpecialIdDescription: json['show_special_id_description']?.toString(),
      showOutOfStockProducts: json['show_out_of_stock_products']?.toString(),
      priceIncludesGstMessage: json['price_includes_gst_message']?.toString(),
      priceExcludesGstMessage: json['price_excludes_gst_message']?.toString(),
      showGstInCart: json['show_gst_in_cart']?.toString(),
      productImageDimensions: json['product_image_dimensions']?.toString(),
      addressesList: json['addresses_list'] != null
          ? (json['addresses_list'] as List)
          .map((i) => AddressItem.fromJson(i))
          .toList()
          : null,
    );
  }
}

class AddressItem {
  String? addressId;
  String? firstName;
  String? lastName;
  String? street;
  String? street2;
  String? suburb;
  String? state;
  String? postcode;
  String? phone;
  String? email;
  String? defaultAddress;
  String? deliveryLocationId;
  String? deliveryLocationCharge;

  AddressItem({
    this.addressId,
    this.firstName,
    this.lastName,
    this.street,
    this.street2,
    this.suburb,
    this.state,
    this.postcode,
    this.phone,
    this.email,
    this.defaultAddress,
    this.deliveryLocationId,
    this.deliveryLocationCharge,
  });

  factory AddressItem.fromJson(Map<String, dynamic> json) {
    return AddressItem(
      addressId: json['address_id']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      street: json['street']?.toString(),
      street2: json['street2']?.toString(),
      suburb: json['suburb']?.toString(),
      state: json['state']?.toString(),
      postcode: json['postcode']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      defaultAddress: json['default_address']?.toString(),
      deliveryLocationId: json['delivery_location_id']?.toString(),
      deliveryLocationCharge: json['delivery_location_charge']?.toString(),
    );
  }
}

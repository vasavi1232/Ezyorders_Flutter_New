import '../../core/utils/common_methods.dart';

class CartResponse {
  int? status;
  String? message;
  List<CartResult?>? results;

  CartResponse({this.status, this.message, this.results});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      status: int.tryParse(json['status']?.toString() ?? "0"),
      message: json['message']?.toString(),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? CartResult.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class CartResult {
  String? subTotal;
  String? subTotalHeading;
  String? totalHeading;
  String? discount;
  String? promo;
  String? orderAmount;
  String? deliveryCharge;
  String? deliveryLocationCharge;
  String? deliveryLocationId;
  String? suppliersExceededShippingCharge;
  String? couponDiscount;
  String? couponName;
  String? gst;
  String? deliveryChargeGst;
  String? levy;
  String? wet;
  String? showShippingSegment;
  String? minOrderAmount;
  String? maxOrderAmount;
  String? minOrderNotificationText;
  String? maxOrderNotificationText;
  String? restrictOnMinOrderAmountNotReached;
  String? restrictOnMaxOrderAmountReached;
  String? maxOrderUnlimited;
  String? showPriceIncludingGst;
  String? showSoldAs;
  String? maximumNumberOfSuppliersProductsForFreeShipping;
  String? allowToReviewOrderBeforeSubmmitting;
  String? showPromo;
  String? shippingSegmentHeading; // Added for Delivery Location heading sync
  String? shippingSegmentText;
  String? showGstInCart;
  List<CartBrand?>? brands;

  CartResult({
    this.subTotal,
    this.subTotalHeading,
    this.totalHeading,
    this.discount,
    this.promo,
    this.orderAmount,
    this.deliveryCharge,
    this.deliveryLocationCharge,
    this.deliveryLocationId,
    this.suppliersExceededShippingCharge,
    this.couponDiscount,
    this.couponName,
    this.gst,
    this.deliveryChargeGst,
    this.levy,
    this.wet,
    this.showShippingSegment,
    this.minOrderAmount,
    this.maxOrderAmount,
    this.minOrderNotificationText,
    this.maxOrderNotificationText,
    this.restrictOnMinOrderAmountNotReached,
    this.restrictOnMaxOrderAmountReached,
    this.maxOrderUnlimited,
    this.showPriceIncludingGst,
    this.showSoldAs,
    this.maximumNumberOfSuppliersProductsForFreeShipping,
    this.allowToReviewOrderBeforeSubmmitting,
    this.showPromo,
    this.shippingSegmentHeading,
    this.shippingSegmentText,
    this.showGstInCart,
    this.brands,
  });

  factory CartResult.fromJson(Map<String, dynamic> json) {
    return CartResult(
      subTotal: json['sub_total']?.toString(),
      subTotalHeading: json['sub_total_heading']?.toString(),
      totalHeading: json['total_heading']?.toString(),
      discount: json['discount']?.toString(),
      promo: json['promo']?.toString(),
      orderAmount: json['order_amount']?.toString(),
      deliveryCharge: json['delivery_charge']?.toString(),
      deliveryLocationCharge: json['delivery_location_charge']?.toString(),
      deliveryLocationId: json['delivery_location_id']?.toString(),
      suppliersExceededShippingCharge:
          json['suppliers_exceeded_shipping_charge']?.toString(),
      couponDiscount: json['coupon_discount']?.toString(),
      couponName: json['coupon_name']?.toString(),
      gst: json['gst']?.toString(),
      deliveryChargeGst: json['delivery_charge_gst']?.toString(),
      levy: json['levy']?.toString(),
      wet: json['wet']?.toString(),
      showShippingSegment: json['show_shipping_segment']?.toString(),
      minOrderAmount: json['minimum_order_amount']?.toString(),
      maxOrderAmount: json['max_order_amount']?.toString(),
      minOrderNotificationText: json['min_order_notification_text']?.toString(),
      maxOrderNotificationText: json['max_order_notification_text']?.toString(),
      restrictOnMinOrderAmountNotReached:
          json['restrict_on_min_order_amount_not_reached']?.toString(),
      restrictOnMaxOrderAmountReached:
          json['restrict_on_max_order_amount_reached']?.toString(),
      maxOrderUnlimited: json['max_order_unlimited']?.toString(),
      showPriceIncludingGst: json['show_price_including_gst']?.toString(),
      showSoldAs: json['show_sold_as']?.toString(),
      maximumNumberOfSuppliersProductsForFreeShipping:
          json['maximum_number_of_suppliers_products_for_free_shipping']
              ?.toString(),
      allowToReviewOrderBeforeSubmmitting:
          json['allow_to_review_order_before_submmitting']?.toString(),
      showPromo: json['show_promo']?.toString(),
      shippingSegmentHeading: json['shipping_segment_heading']?.toString(), // Added for Delivery Location heading sync
      shippingSegmentText: json['shipping_segment_text']?.toString(),
      showGstInCart: json['show_gst_in_cart']?.toString(),
      brands: json['brands'] != null
          ? (json['brands'] as List)
              .map((i) => i != null ? CartBrand.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class CartBrand {
  String? brandId;
  String? brandName;
  List<CartProduct?>? products;

  CartBrand({this.brandId, this.brandName, this.products});

  factory CartBrand.fromJson(Map<String, dynamic> json) {
    return CartBrand(
      brandId: json['brand_id']?.toString(),
      brandName: json['brand_name']?.toString(),
      products: json['products'] != null
          ? (json['products'] as List)
              .map((i) => i != null ? CartProduct.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class CartProduct {
  String? productId;
  String? title;
  String? image;
  String? minimumOrderQty;
  int? qty;
  String? gstPercentage;
  String? gstAmount;
  String? gstPrice;
  String? normalPrice;
  String? salePrice;
  String? supplierAvailable;
  String? productAvailable;
  String? notAvailableDaysMessage;
  String? discountAmount;
  String? soldAs;
  String? orderedAs;
  String? brandId;
  String? brandName;
  String? stockUnlimited;
  String? qtyStatus;
  String? availableStockQty;
  String? qtyPerOuter;
  String? discountId;
  String? discountName;
  String? specialId;
  String? specialName;
  String? allowToOrder;

  CartProduct({
    this.productId,
    this.title,
    this.image,
    this.minimumOrderQty,
    this.qty,
    this.gstPercentage,
    this.gstAmount,
    this.gstPrice,
    this.normalPrice,
    this.salePrice,
    this.supplierAvailable,
    this.productAvailable,
    this.notAvailableDaysMessage,
    this.discountAmount,
    this.soldAs,
    this.orderedAs,
    this.brandId,
    this.brandName,
    this.stockUnlimited,
    this.qtyStatus,
     this.availableStockQty,
    this.qtyPerOuter,
    this.discountId,
    this.discountName,
    this.specialId,
    this.specialName,
    this.allowToOrder,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      productId: json['product_id']?.toString().trim(),
      title: json['title']?.toString(),
      image: json['image']?.toString(),
      minimumOrderQty: json['minimum_order_qty']?.toString(),
      qty: int.tryParse(json['qty']?.toString() ?? "0"),
      gstPercentage: json['gst_percentage']?.toString(),
      gstAmount: json['gst_amount']?.toString(),
      gstPrice: json['gst_price']?.toString(),
      normalPrice: json['normal_price']?.toString(),
      salePrice: json['sale_price']?.toString(),
      supplierAvailable: json['supplier_available']?.toString(),
      productAvailable: json['product_available']?.toString(),
      notAvailableDaysMessage: json['not_available_days_message']?.toString(),
      discountAmount: json['discount_amount']?.toString(),
      soldAs: json['sold_as']?.toString(),
      orderedAs: json['ordered_as']?.toString(),
      stockUnlimited: json['stock_unlimited']?.toString(),
      qtyStatus: json['qty_status']?.toString(),
      availableStockQty: json['available_stock_qty']?.toString(),
      qtyPerOuter: json['qty_per_outer']?.toString(),
      discountId: json['discount_id']?.toString(),
      discountName: json['discount_name']?.toString(),
      specialId: json['special_id']?.toString(),
      specialName: json['special_name']?.toString(),
      allowToOrder: json['allow_to_order']?.toString() ?? json['allow_order']?.toString(),
    );
  }
  String? get discountPercent {
    try {
      double normal = double.tryParse(normalPrice ?? "0") ?? 0;
      double sale = double.tryParse(salePrice ?? "0") ?? 0;
      // Match native Android: findDiscount(normalPrice, salePrice)
      // = (1 - salePrice / normalPrice) * 100, with CEILING rounding
      if (normal > 0 && sale > 0 && sale < normal) {
        return CommonMethods.calculateDiscount(normalPrice, salePrice);
      }
    } catch (e) {
      return null;
    }
    return null;
  }
  int calculateMaxQty() {
    // Aggressive normalization of values
    final String sunl = (stockUnlimited ?? "").toLowerCase().trim();
    final String qstat = (qtyStatus ?? "").toLowerCase().trim();
    final String ato = (allowToOrder ?? "").toLowerCase().trim();

    // If company allows ordering, stock is unlimited, or status is missing/low, allow high limit
    if (ato == "yes" || ato == "1" || sunl == "yes" || qstat == "low in stock" || qstat == "") {
      return 1000;
    }

    // Default to available stock
    int stock = int.tryParse(availableStockQty ?? "0") ?? 1000;
    int minOrder = int.tryParse(minimumOrderQty ?? "1") ?? 1;
    
    // Safety check: if stock is 0 but it's not explicitly 'out of stock', allow high limit
    if (stock <= 0 && qstat != "out of stock") {
      return 1000;
    }

    return stock < minOrder ? minOrder : stock;
  }
}

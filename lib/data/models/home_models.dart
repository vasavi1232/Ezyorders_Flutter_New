class BannersResponse {
  int? status;
  String? message;
  List<BannerItem?>? results;

  BannersResponse({this.status, this.message, this.results});

  factory BannersResponse.fromJson(Map<String, dynamic> json) {
    return BannersResponse(
      status: json['status'],
      message: json['message'],
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? BannerItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class BannerItem {
  String? bannerId; // banner_id
  String? name; // name (was banner_title)
  String? image; // image (was banner_image)
  String? topCaption; // top_caption
  String? bottomCaption; // bottom_caption
  String? linkImageTo; // link_image_to
  String? divisionId; // division_id
  String? groupId; // group_id
  String? productId; // product_id
  String? sortOrder; // sort_order
  String? externalLink; // external_link
  String? products; // products

  BannerItem({
    this.bannerId,
    this.name,
    this.image,
    this.topCaption,
    this.bottomCaption,
    this.linkImageTo,
    this.divisionId,
    this.groupId,
    this.productId,
    this.sortOrder,
    this.externalLink,
    this.products,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      bannerId: json['banner_id']?.toString(),
      name: json['name']?.toString(),
      image: json['image']?.toString(),
      topCaption: json['top_caption']?.toString(),
      bottomCaption: json['bottom_caption']?.toString(),
      linkImageTo: json['link_image_to']?.toString(),
      divisionId: json['division_id']?.toString(),
      groupId: json['group_id']?.toString(),
      productId: json['product_id']?.toString(),
      sortOrder: json['sort_order']?.toString(),
      externalLink: json['external_link']?.toString(),
      products: json['products']?.toString(),
    );
  }
}

class FooterBannersResponse {
  int? status;
  String? message;
  List<BannerItem?>? results;

  FooterBannersResponse({this.status, this.message, this.results});
  factory FooterBannersResponse.fromJson(Map<String, dynamic> json) {
    return FooterBannersResponse(
      status: json['status'],
      message: json['message'],
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? BannerItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class HomeBlocksResponse {
  int? status;
  String? message;
  List<HomeBlockItem?>? results;

  HomeBlocksResponse({this.status, this.message, this.results});
  factory HomeBlocksResponse.fromJson(Map<String, dynamic> json) {
    return HomeBlocksResponse(
      status: json['status'],
      message: json['message'],
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? HomeBlockItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class HomeBlockItem {
  String? id;
  String? companyId;
  String? name;
  String? image;
  String? description;
  String? sortOrder;
  String? status;

  HomeBlockItem(
      {this.id,
      this.companyId,
      this.name,
      this.image,
      this.description,
      this.sortOrder,
      this.status});

  factory HomeBlockItem.fromJson(Map<String, dynamic> json) {
    return HomeBlockItem(
      id: json['id']?.toString(),
      companyId: json['company_id']?.toString(),
      name: json['name']?.toString(),
      image: json['image']?.toString(),
      description: json['description']?.toString(),
      sortOrder: json['sort_order']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class ProductItem {
  String? productId;
  String? name; // Added for ProductDetailItem compatibility
  String? title;
  String? description;
  String? shortDescription; // Added for ProductDetailItem compatibility
  String? image;
  String? brandName;
  String? brandId;
  String? price;
  String? promotionPrice;
  String? stockUnlimited;
  String? qtyStatus;
  String? availableStockQty;
  String? minimumOrderQty;
  String? soldAs;
  String? isFavourite;
  String? productAvailable; // Changed to String to handle 1/"1"
  String? supplierAvailable; // Changed to String
  String? notAvailableDaysMessage;
  String? addedToCart;
  String? addedQty;
  String? addedSubTotal;
  String? orderedAs;
  String? qtyPerOuter; // Added for unit logic
  String? apiData;
  String? divisionId;
  String? groupId;
  String? sku;
  String? gst; // Added for ProductDetailItem compatibility
  String? gstPercentage;
  String? fromDate;
  String? toDate;
  String? hasPromotion; // Added field
  String?
      label; // Added for promotional badges (Best Seller, New Arrival, etc.)
  String? discountPercentage; // Added for ProductDetailItem compatibility
  String? discountId; // Added for ProductDetailItem compatibility
  String? discountName; // Added for ProductDetailItem compatibility
  String? specialId;
  String? specialName;
  String? wishlistId; // Added for Wishlist
  String? wishlistCategoryId; // Added for Wishlist
  String? allowToOrder; // Added for ordering restriction
  List<ProductItem>? products; // Added for Promotions Banner nested products

  ProductItem({
    this.productId,
    this.name,
    this.title,
    this.description,
    this.shortDescription,
    this.image,
    this.brandName,
    this.brandId,
    this.price,
    this.promotionPrice,
    this.stockUnlimited,
    this.qtyStatus,
    this.availableStockQty,
    this.minimumOrderQty,
    this.soldAs,
    this.isFavourite,
    this.productAvailable,
    this.supplierAvailable,
    this.notAvailableDaysMessage,
    this.addedToCart,
    this.addedQty,
    this.addedSubTotal,
    this.orderedAs,
    this.qtyPerOuter,
    this.apiData,
    this.divisionId,
    this.groupId,
    this.sku,
    this.gst,
    this.gstPercentage,
    this.fromDate,
    this.toDate,
    this.hasPromotion,
    this.label,
    this.discountPercentage,
    this.discountId,
    this.discountName,
    this.specialId,
    this.specialName,
    this.wishlistId,
    this.wishlistCategoryId,
    this.allowToOrder,
    this.products,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      productId: json['product_id']?.toString().trim(),
      name: json['name']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      shortDescription: json['short_description']?.toString(),
      image: json['image']?.toString(),
      brandName: json['brand_name']?.toString(),
      brandId: json['brand_id']?.toString(),
      price: json['price']?.toString(),
      promotionPrice: json['promotion_price']?.toString(),
      stockUnlimited: json['stock_unlimited']?.toString(),
      qtyStatus: json['qty_status']?.toString(),
      availableStockQty: json['available_stock_qty']?.toString(),
      minimumOrderQty: json['minimum_order_qty']?.toString(),
      soldAs: json['sold_as']?.toString(),
      isFavourite: json['is_favourite']?.toString(),
      productAvailable: json['product_available']?.toString(),
      supplierAvailable: json['supplier_available']?.toString(),
      notAvailableDaysMessage: json['not_available_days_message']?.toString(),
      addedToCart: json['added_to_cart']?.toString(),
      addedQty: json['added_qty']?.toString(),
      addedSubTotal: json['added_sub_total']?.toString(),
      orderedAs: json['ordered_as']?.toString(),
      qtyPerOuter: json['qty_per_outer']?.toString(),
      apiData: json['api_data']?.toString(),
      divisionId: json['division_id']?.toString(),
      groupId: json['group_id']?.toString(),
      sku: json['sku']?.toString(),
      gst: json['gst']?.toString(),
      gstPercentage: json['gst_percentage']?.toString(),
      fromDate: json['from_date']?.toString().isNotEmpty == true
          ? json['from_date'].toString()
          : json['promotion_from_date_time']?.toString(),
      toDate: json['to_date']?.toString().isNotEmpty == true
          ? json['to_date'].toString()
          : json['promotion_to_date_time']?.toString(),
      hasPromotion: json['has_promotion']?.toString(),
      label: json['label']?.toString(),
      discountPercentage: json['discount_percentage']?.toString(),
      discountId: json['discount_id']?.toString(),
      discountName: json['discount_name']?.toString(),
      specialId: json['special_id']?.toString(),
      specialName: json['special_name']?.toString(),
      wishlistId: json['wishlist_id']?.toString(),
      wishlistCategoryId: json['wishlist_category_id']?.toString(),
      allowToOrder: json['allow_to_order']?.toString(),
      products: json['products'] != null
          ? (json['products'] as List)
              .map((i) => i != null ? ProductItem.fromJson(i) : null)
              .whereType<ProductItem>()
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'title': title,
      'description': description,
      'short_description': shortDescription,
      'image': image,
      'brand_name': brandName,
      'brand_id': brandId,
      'price': price,
      'promotion_price': promotionPrice,
      'stock_unlimited': stockUnlimited,
      'qty_status': qtyStatus,
      'available_stock_qty': availableStockQty,
      'minimum_order_qty': minimumOrderQty,
      'sold_as': soldAs,
      'is_favourite': isFavourite,
      'product_available': productAvailable,
      'supplier_available': supplierAvailable,
      'not_available_days_message': notAvailableDaysMessage,
      'added_to_cart': addedToCart,
      'added_qty': addedQty,
      'added_sub_total': addedSubTotal,
      'ordered_as': orderedAs,
      'qty_per_outer': qtyPerOuter,
      'api_data': apiData,
      'division_id': divisionId,
      'group_id': groupId,
      'sku': sku,
      'gst': gst,
      'gst_percentage': gstPercentage,
      'from_date': fromDate,
      'to_date': toDate,
      'has_promotion': hasPromotion,
      'label': label,
      'discount_percentage': discountPercentage,
      'discount_id': discountId,
      'discount_name': discountName,
      'special_id': specialId,
      'special_name': specialName,
      'wishlist_id': wishlistId,
      'wishlist_category_id': wishlistCategoryId,
      'allow_to_order': allowToOrder,
      'products': products?.map((e) => e.toJson()).toList(),
    };
  }
}

class DashboardProductsResponse {
  int? status;
  String? message;
  int? totalPages;
  int? totalRecords;
  List<ProductItem?>? results;

  DashboardProductsResponse({this.status, this.message, this.totalPages, this.totalRecords, this.results});
  factory DashboardProductsResponse.fromJson(Map<String, dynamic> json) {
    return DashboardProductsResponse(
      status: json['status'],
      message: json['message'],
      totalPages: json['total_pages'] is int ? json['total_pages'] : int.tryParse(json['total_pages']?.toString() ?? ''),
      totalRecords: json['total_records'] is int ? json['total_records'] : int.tryParse(json['total_records']?.toString() ?? ''),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? ProductItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class PromotionsResponse {
  int? status;
  String? message;
  int? totalPages;
  int? totalRecords;
  List<ProductItem?>? results;

  PromotionsResponse({this.status, this.message, this.totalPages, this.totalRecords, this.results});
  factory PromotionsResponse.fromJson(Map<String, dynamic> json) {
    return PromotionsResponse(
      status: json['status'],
      message: json['message'],
      totalPages: json['total_pages'] is int ? json['total_pages'] : int.tryParse(json['total_pages']?.toString() ?? ''),
      totalRecords: json['total_records'] is int ? json['total_records'] : int.tryParse(json['total_records']?.toString() ?? ''),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? ProductItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class FlashDealsResponse {
  int? status;
  String? message;
  int? totalPages;
  int? totalRecords;
  List<ProductItem?>? results;

  FlashDealsResponse({this.status, this.message, this.totalPages, this.totalRecords, this.results});
  factory FlashDealsResponse.fromJson(Map<String, dynamic> json) {
    return FlashDealsResponse(
      status: json['status'],
      message: json['message'],
      totalPages: json['total_pages'] is int ? json['total_pages'] : int.tryParse(json['total_pages']?.toString() ?? ''),
      totalRecords: json['total_records'] is int ? json['total_records'] : int.tryParse(json['total_records']?.toString() ?? ''),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? ProductItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class PopularCategoryItem {
  String? divisionId;
  String? groupLevel1;
  String? image;
  String? popularCategory;
  String? categoryProductsCount; // Added

  PopularCategoryItem(
      {this.divisionId,
      this.groupLevel1,
      this.image,
      this.popularCategory,
      this.categoryProductsCount});

  factory PopularCategoryItem.fromJson(Map<String, dynamic> json) {
    return PopularCategoryItem(
      divisionId: json['division_id']?.toString(),
      groupLevel1: json['group_level_1']?.toString(),
      image: json['image']?.toString(),
      popularCategory: json['popular_category']?.toString(),
      categoryProductsCount: json['category_products_count']?.toString(),
    );
  }
}

class PopularCategoriesResponse {
  int? status;
  String? message;
  int? totalPages;
  int? totalRecords;
  List<PopularCategoryItem?>? results;

  PopularCategoriesResponse({this.status, this.message, this.totalPages, this.totalRecords, this.results});
  factory PopularCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return PopularCategoriesResponse(
      status: json['status'],
      message: json['message'],
      totalPages: json['total_pages'] is int ? json['total_pages'] : int.tryParse(json['total_pages']?.toString() ?? ''),
      totalRecords: json['total_records'] is int ? json['total_records'] : int.tryParse(json['total_records']?.toString() ?? ''),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? PopularCategoryItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class BrandItem {
  String? brandId;
  String? brandName;
  String? image;
  String? brandNumber;
  String? topBrand;
  String? majorBrand;
  String? status;
  String? companyId;

  BrandItem(
      {this.brandId,
      this.brandName,
      this.image,
      this.brandNumber,
      this.topBrand,
      this.majorBrand,
      this.status,
      this.companyId});

  factory BrandItem.fromJson(Map<String, dynamic> json) {
    return BrandItem(
      brandId: json['brand_id']?.toString(),
      brandName: json['brand_name']?.toString(),
      image: json['image']?.toString(),
      brandNumber: json['brand_number']?.toString(),
      topBrand: json['top_brand']?.toString(),
      majorBrand: json['major_brand']?.toString(),
      status: json['status']?.toString(),
      companyId: json['company_id']?.toString(),
    );
  }
}

class SupplierLogosResponse {
  int? status;
  String? message;
  int? totalPages;
  int? totalRecords;
  List<BrandItem?>? results;

  SupplierLogosResponse({this.status, this.message, this.totalPages, this.totalRecords, this.results});
  factory SupplierLogosResponse.fromJson(Map<String, dynamic> json) {
    return SupplierLogosResponse(
      status: json['status'],
      message: json['message'],
      totalPages: json['total_pages'] is int ? json['total_pages'] : int.tryParse(json['total_pages']?.toString() ?? ''),
      totalRecords: json['total_records'] is int ? json['total_records'] : int.tryParse(json['total_records']?.toString() ?? ''),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? BrandItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class PopularAdvertisementsResponse {
  int? status;
  String? message;
  int? totalPages;
  int? totalRecords;
  List<BannerItem?>? results;

  PopularAdvertisementsResponse({this.status, this.message, this.totalPages, this.totalRecords, this.results});
  factory PopularAdvertisementsResponse.fromJson(Map<String, dynamic> json) {
    return PopularAdvertisementsResponse(
      status: json['status'],
      message: json['message'],
      totalPages: json['total_pages'] is int ? json['total_pages'] : int.tryParse(json['total_pages']?.toString() ?? ''),
      totalRecords: json['total_records'] is int ? json['total_records'] : int.tryParse(json['total_records']?.toString() ?? ''),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? BannerItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}


extension ProductItemCopyWith on ProductItem {
  ProductItem copyWith({
    String? addedToCart,
    String? addedQty,
    String? addedSubTotal,
    String? orderedAs,
    String? isFavourite,
  }) {
    return ProductItem(
      productId: productId,
      name: name,
      title: title,
      description: description,
      shortDescription: shortDescription,
      image: image,
      brandName: brandName,
      brandId: brandId,
      price: price,
      promotionPrice: promotionPrice,
      stockUnlimited: stockUnlimited,
      qtyStatus: qtyStatus,
      availableStockQty: availableStockQty,
      minimumOrderQty: minimumOrderQty,
      soldAs: soldAs,
      isFavourite: isFavourite ?? this.isFavourite,
      productAvailable: productAvailable,
      supplierAvailable: supplierAvailable,
      notAvailableDaysMessage: notAvailableDaysMessage,
      addedToCart: addedToCart ?? this.addedToCart,
      addedQty: addedQty ?? this.addedQty,
      addedSubTotal: addedSubTotal ?? this.addedSubTotal,
      orderedAs: orderedAs ?? this.orderedAs,
      qtyPerOuter: qtyPerOuter,
      apiData: apiData,
      divisionId: divisionId,
      groupId: groupId,
      sku: sku,
      gst: gst,
      gstPercentage: gstPercentage,
      fromDate: fromDate,
      toDate: toDate,
      hasPromotion: hasPromotion,
      label: label,
      discountPercentage: discountPercentage,
      discountId: discountId,
      discountName: discountName,
      specialId: specialId,
      specialName: specialName,
      wishlistId: wishlistId,
      wishlistCategoryId: wishlistCategoryId,
      allowToOrder: allowToOrder,
      products: products,
    );
  }
}

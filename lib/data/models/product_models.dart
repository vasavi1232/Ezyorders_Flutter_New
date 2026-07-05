import 'home_models.dart';

class ProductsResponse {
  int? status;
  String? message;
  int? resultsCount;
  int? totalPages;
  String? totalRecords;
  List<ProductItem?>? results;

  ProductsResponse({
    this.status,
    this.message,
    this.resultsCount,
    this.totalPages,
    this.totalRecords,
    this.results,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      status: json['status'],
      message: json['message'],
      resultsCount: json['results_count'],
      totalPages: json['total_pages'],
      totalRecords: json['total_records']?.toString(),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? ProductItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class FilterProductResponse {
  int? status;
  String? message;
  List<FilterDivision?>? divisions;
  int? divisionsCount;
  List<FilterSupplier?>? suppliers;
  int? suppliersCount;
  List<FilterTag?>? tags;
  int? tagsCount;
  List<FilterGroup?>? groups;
  int? groupsCount;
  List<FilterGroup?>? groupNames;
  int? groupNamesCount;
  List<FilterDivisionName?>? divisionNames;
  int? divisionNamesCount;
  List<FilterSubGroup?>? subGroups;
  int? subGroupsCount;
  List<FilterSubGroup?>? subGroupNames;
  int? subGroupNamesCount;

  FilterProductResponse({
    this.status,
    this.message,
    this.divisions,
    this.divisionsCount,
    this.suppliers,
    this.suppliersCount,
    this.tags,
    this.tagsCount,
    this.groups,
    this.groupsCount,
    this.groupNames,
    this.groupNamesCount,
    this.divisionNames,
    this.divisionNamesCount,
    this.subGroups,
    this.subGroupsCount,
    this.subGroupNames,
    this.subGroupNamesCount,
  });

  factory FilterProductResponse.fromJson(Map<String, dynamic> json) {
    return FilterProductResponse(
      status: json['status'],
      message: json['message'],
      divisionsCount: json['divisions_count'],
      divisions: json['divisions'] != null
          ? (json['divisions'] as List)
              .map((i) => i != null ? FilterDivision.fromJson(i) : null)
              .toList()
          : null,
      suppliersCount: json['suppliers_count'],
      suppliers: json['suppliers'] != null
          ? (json['suppliers'] as List)
              .map((i) => i != null ? FilterSupplier.fromJson(i) : null)
              .toList()
          : null,
      tagsCount: json['tags_count'],
      tags: json['tags'] != null
          ? (json['tags'] as List)
              .map((i) => i != null ? FilterTag.fromJson(i) : null)
              .toList()
          : null,
      groupsCount: json['groups_count'],
      groups: json['groups'] != null
          ? (json['groups'] as List)
              .map((i) => i != null ? FilterGroup.fromJson(i) : null)
              .toList()
          : null,
      groupNamesCount: json['group_names_count'],
      groupNames: json['group_names'] != null
          ? (json['group_names'] as List)
              .map((i) => i != null ? FilterGroup.fromJson(i) : null)
              .toList()
          : null,
      divisionNamesCount: json['division_names_count'],
      divisionNames: json['division_names'] != null
          ? (json['division_names'] as List)
              .map((i) => i != null ? FilterDivisionName.fromJson(i) : null)
              .toList()
          : null,
      subGroupsCount: json['sub_groups_count'],
      subGroups: json['sub_groups'] != null
          ? (json['sub_groups'] as List)
              .map((i) => i != null ? FilterSubGroup.fromJson(i) : null)
              .toList()
          : null,
      subGroupNamesCount: json['sub_group_names_count'],
      subGroupNames: json['sub_group_names'] != null
          ? (json['sub_group_names'] as List)
              .map((i) => i != null ? FilterSubGroup.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class FilterSubGroup {
  String? subGroupId;
  String? groupLevel3;
  int? products;
  String? groupSelected;

  FilterSubGroup({
    this.subGroupId,
    this.groupLevel3,
    this.products,
    this.groupSelected = "No",
  });

  factory FilterSubGroup.fromJson(Map<String, dynamic> json) {
    return FilterSubGroup(
      subGroupId: json['sub_group_id']?.toString(),
      groupLevel3: json['group_level_3']?.toString(),
      products: json['products'],
      groupSelected: json['group_selected']?.toString() ?? "No",
    );
  }
}

class FilterDivision {
  String? divisionId;
  String? groupLevel1;
  String? products;
  String? selected;

  FilterDivision({
    this.divisionId,
    this.groupLevel1,
    this.products,
    this.selected = "No",
  });

  factory FilterDivision.fromJson(Map<String, dynamic> json) {
    return FilterDivision(
      divisionId: json['division_id']?.toString(),
      groupLevel1: json['group_level_1']?.toString(),
      products: json['products']?.toString(),
      selected: json['selected']?.toString() ?? "No",
    );
  }
}

class FilterSupplier {
  String? brandId;
  String? brandName;
  String? products;
  String? modUrl;
  String? selected;

  FilterSupplier({
    this.brandId,
    this.brandName,
    this.products,
    this.modUrl,
    this.selected = "No",
  });

  factory FilterSupplier.fromJson(Map<String, dynamic> json) {
    return FilterSupplier(
      brandId: json['brand_id']?.toString(),
      brandName: json['brand_name']?.toString(),
      products: json['products']?.toString(),
      modUrl: json['mod_url']?.toString(),
      selected: json['selected']?.toString() ?? "No",
    );
  }
}

class FilterTag {
  String? tagId;
  String? tagName;
  String? tagSelected;

  FilterTag({
    this.tagId,
    this.tagName,
    this.tagSelected = "No",
  });

  factory FilterTag.fromJson(Map<String, dynamic> json) {
    return FilterTag(
      tagId: json['tag_id']?.toString(),
      tagName: json['tag_name']?.toString(),
      tagSelected: json['tag_selected']?.toString() ?? "No",
    );
  }
}

class FilterGroup {
  String? groupId;
  String? groupLevel2;
  int? products;
  String? groupSelected;

  FilterGroup({
    this.groupId,
    this.groupLevel2,
    this.products,
    this.groupSelected = "No",
  });

  factory FilterGroup.fromJson(Map<String, dynamic> json) {
    return FilterGroup(
      groupId: json['group_id']?.toString(),
      groupLevel2: json['group_level_2']?.toString(),
      products: json['products'],
      groupSelected: json['group_selected']?.toString() ?? "No",
    );
  }
}

class FilterDivisionName {
  String? groupLevel1;
  String? products;

  FilterDivisionName({
    this.groupLevel1,
    this.products,
  });

  factory FilterDivisionName.fromJson(Map<String, dynamic> json) {
    return FilterDivisionName(
      groupLevel1: json['group_level_1']?.toString(),
      products: json['products']?.toString(),
    );
  }
}

class ProductSortResponse {
  int? status;
  String? message;
  int? resultsCount;
  List<SortItem?>? results;

  ProductSortResponse({
    this.status,
    this.message,
    this.resultsCount,
    this.results,
  });

  factory ProductSortResponse.fromJson(Map<String, dynamic> json) {
    return ProductSortResponse(
      status: json['status'],
      message: json['message'],
      resultsCount: json['results_count'],
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? SortItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class SortItem {
  String? value;
  String? name;
  String? selected;

  SortItem({this.value, this.name, this.selected = "No"});

  factory SortItem.fromJson(Map<String, dynamic> json) {
    return SortItem(
      value: json['value']?.toString(),
      name: json['name']?.toString(),
      selected: json['selected']?.toString() ?? "No",
    );
  }
}

class ProductDetailsResponse {
  int? status;
  String? message;
  int? resultsCount;
  List<ProductDetailItem?>? results;

  ProductDetailsResponse({
    this.status,
    this.message,
    this.resultsCount,
    this.results,
  });

  factory ProductDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ProductDetailsResponse(
      status: json['status'],
      message: json['message'],
      resultsCount: json['results_count'],
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? ProductDetailItem.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class ProductDetailItem extends ProductItem {
  List<ProductField?>? productFields;
  List<ProductSpecification?>? productSpecifications;
  List<ProductItem?>? similarProducts;
  List<ProductItem?>? sameCategoryProducts;
  String? item;
  // String? sku; // Removed override
  String? unitsShipper;
  String? innerBarcode;
  String? shipperBarcode;
  String? outerBarcode;
  String? primaryBarcode;
  String? hasSimilarProducts;
  int? similarProductsCount;
  String? hasSameCategoryProducts;
  int? sameCategoryProductsCount;

  ProductDetailItem({
    super.addedToCart,
    super.addedQty,
    super.addedSubTotal,
    super.productId,
    super.name, // Mapping 'title' to 'name' for consistency with ProductItem
    super.title, // Added to ensure title is populated
    super.description,
    super.shortDescription,
    super.image,
    super.brandName,
    super.brandId,
    super.price,
    super.promotionPrice,
    super.stockUnlimited,
    super.qtyStatus,
    super.availableStockQty,
    super.minimumOrderQty,
    super.soldAs,
    super.gst,
    super.gstPercentage,
    super.hasPromotion,
    super.label,
    super.productAvailable,
    super.supplierAvailable,
    super.notAvailableDaysMessage,
    super.isFavourite,
    super.discountPercentage,
    super.discountId,
    super.discountName,
    super.qtyPerOuter,
    super.orderedAs,
    super.apiData,
    super.specialId,
    super.specialName,
    super.sku,
    super.allowToOrder,
    this.productFields,
    this.productSpecifications,
    this.similarProducts,
    this.sameCategoryProducts,
    this.item,
    // this.sku, // Removed
    this.unitsShipper,
    this.innerBarcode,
    this.shipperBarcode,
    this.outerBarcode,
    this.primaryBarcode,
    this.hasSimilarProducts,
    this.similarProductsCount,
    this.hasSameCategoryProducts,
    this.sameCategoryProductsCount,
  });

  factory ProductDetailItem.fromJson(Map<String, dynamic> json) {
    final base = ProductItem.fromJson(json);
    return ProductDetailItem(
      addedToCart: base.addedToCart,
      addedQty: base.addedQty,
      addedSubTotal: base.addedSubTotal,
      productId: base.productId,
      name: json['title']?.toString() ?? base.name,
      title: json['title']?.toString() ?? json['name']?.toString() ?? base.title, // Ensure title is set
      description: base.description,
      shortDescription: base.shortDescription,
      image: base.image,
      brandName: base.brandName,
      brandId: base.brandId,
      price: base.price,
      promotionPrice: base.promotionPrice,
      stockUnlimited: base.stockUnlimited,
      qtyStatus: base.qtyStatus,
      availableStockQty: base.availableStockQty,
      minimumOrderQty: base.minimumOrderQty,
      soldAs: base.soldAs,
      gst: base.gst,
      gstPercentage: base.gstPercentage,
      hasPromotion: base.hasPromotion,
      label: base.label,
      productAvailable: base.productAvailable,
      supplierAvailable: base.supplierAvailable,
      notAvailableDaysMessage: base.notAvailableDaysMessage,
      isFavourite: base.isFavourite,
      discountPercentage: base.discountPercentage,
      discountId: base.discountId,
      discountName: base.discountName,
      qtyPerOuter: base.qtyPerOuter,
      orderedAs: base.orderedAs,
      specialId: base.specialId,
      specialName: base.specialName,
      allowToOrder: base.allowToOrder,
      productFields: json['product_fields'] != null
          ? (json['product_fields'] as List)
              .map((i) => i != null ? ProductField.fromJson(i) : null)
              .toList()
          : null,
      productSpecifications: json['product_specifications'] != null
          ? (json['product_specifications'] as List)
              .map((i) => i != null ? ProductSpecification.fromJson(i) : null)
              .toList()
          : null,
      similarProducts: json['similar_products'] != null
          ? (json['similar_products'] as List)
              .map((i) => i != null ? ProductItem.fromJson(i) : null)
              .toList()
          : null,
      sameCategoryProducts: json['same_category_products'] != null
          ? (json['same_category_products'] as List)
              .map((i) => i != null ? ProductItem.fromJson(i) : null)
              .toList()
          : null,
      item: json['item']?.toString(),
      sku: json['sku']?.toString(),
      unitsShipper: json['units_shipper']?.toString(),
      innerBarcode: json['inner_barcode']?.toString(),
      shipperBarcode: json['shipper_barcode']?.toString(),
      outerBarcode: json['outer_barcode']?.toString(),
      primaryBarcode: json['primary_barcode']?.toString(),
      hasSimilarProducts: json['has_similar_products']?.toString(),
      similarProductsCount: int.tryParse(json['similar_products_count']?.toString() ?? "0"),
      hasSameCategoryProducts: json['has_same_category_products']?.toString(),
      sameCategoryProductsCount: int.tryParse(json['same_category_products_count']?.toString() ?? "0"),
    );
  }
}

class ProductField {
  String? name;

  ProductField({this.name});

  factory ProductField.fromJson(Map<String, dynamic> json) {
    return ProductField(name: json['name']?.toString());
  }
}

class ProductSpecification {
  String? id;
  String? specificationId;
  String? productId;
  String? description;
  String? specification;

  ProductSpecification({
    this.id,
    this.specificationId,
    this.productId,
    this.description,
    this.specification,
  });

  factory ProductSpecification.fromJson(Map<String, dynamic> json) {
    return ProductSpecification(
      id: json['id']?.toString(),
      specificationId: json['specification_id']?.toString(),
      productId: json['product_id']?.toString(),
      description: json['description']?.toString(),
      specification: json['specification']?.toString(),
    );
  }
}

extension ProductDetailItemCopyWith on ProductDetailItem {
  ProductDetailItem copyDetailWith({
    String? addedToCart,
    String? addedQty,
    String? addedSubTotal,
    String? orderedAs,
    String? isFavourite,
    String? allowToOrder,
  }) {
    return ProductDetailItem(
      addedToCart: addedToCart ?? this.addedToCart,
      addedQty: addedQty ?? this.addedQty,
      addedSubTotal: addedSubTotal ?? this.addedSubTotal,
      orderedAs: orderedAs ?? this.orderedAs,
      isFavourite: isFavourite ?? this.isFavourite,
      allowToOrder: allowToOrder ?? this.allowToOrder,
      // Pass through all other fields
      productId: productId,
      name: name,
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
      gst: gst,
      gstPercentage: gstPercentage,
      hasPromotion: hasPromotion,
      label: label,
      productAvailable: productAvailable,
      supplierAvailable: supplierAvailable,
      notAvailableDaysMessage: notAvailableDaysMessage,
      discountPercentage: discountPercentage,
      discountId: discountId,
      discountName: discountName,
      qtyPerOuter: qtyPerOuter,
      specialId: specialId,
      specialName: specialName,
      apiData: apiData,

      productFields: productFields,
      productSpecifications: productSpecifications,
      similarProducts: similarProducts,
      sameCategoryProducts: sameCategoryProducts,
      item: item,
      sku: sku,
      unitsShipper: unitsShipper,
      innerBarcode: innerBarcode,
      shipperBarcode: shipperBarcode,
      outerBarcode: outerBarcode,
      primaryBarcode: primaryBarcode,
      hasSimilarProducts: hasSimilarProducts ?? this.hasSimilarProducts,
      similarProductsCount: similarProductsCount ?? this.similarProductsCount,
      hasSameCategoryProducts: hasSameCategoryProducts ?? this.hasSameCategoryProducts,
      sameCategoryProductsCount: sameCategoryProductsCount ?? this.sameCategoryProductsCount,
    );
  }
}

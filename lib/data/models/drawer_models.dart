class NotificationResponse {
  int? resultsCount;
  String? message;
  int? status;
  List<NotificationItem>? results;

  NotificationResponse(
      {this.resultsCount, this.message, this.status, this.results});

  NotificationResponse.fromJson(Map<String, dynamic> json) {
    resultsCount = json['results_count'];
    message = json['message'];
    status = json['status'];
    if (json['results'] != null) {
      results = <NotificationItem>[];
      json['results'].forEach((v) {
        results!.add(NotificationItem.fromJson(v));
      });
    }
  }
}

class NotificationItem {
  String? notificationId;
  String? title;
  String? description;
  String? status;
  String? iconStatus;
  String? checkStatus;
  String? image;
  String? imagePosition;

  NotificationItem(
      {this.notificationId,
      this.title,
      this.description,
      this.status,
      this.iconStatus,
      this.checkStatus,
      this.image,
      this.imagePosition});

  NotificationItem.fromJson(Map<String, dynamic> json) {
    notificationId = json['notification_id']?.toString();
    title = json['title'];
    description = json['description'];
    status = json['status'];
    iconStatus = json['icon_status'];
    checkStatus = json['check_status'];
    image = json['image'];
    imagePosition = json['image_position'];
  }
}

class FAQResponse {
  int? resultsCount;
  String? message;
  int? status;
  List<FAQCategory>? results;

  FAQResponse({this.resultsCount, this.message, this.status, this.results});

  FAQResponse.fromJson(Map<String, dynamic> json) {
    resultsCount = json['results_count'];
    message = json['message'];
    status = json['status'];
    if (json['results'] != null) {
      results = <FAQCategory>[];
      json['results'].forEach((v) {
        results!.add(FAQCategory.fromJson(v));
      });
    }
  }
}

class FAQCategory {
  String? categoryId;
  String? categoryName;

  FAQCategory({this.categoryId, this.categoryName});

  FAQCategory.fromJson(Map<String, dynamic> json) {
    categoryId = json['category_id']?.toString();
    categoryName = json['category_name'];
  }
}

class FAQDetailsResponse {
  int? resultsCount;
  String? message;
  int? status;
  List<FAQItem>? results;

  FAQDetailsResponse(
      {this.resultsCount, this.message, this.status, this.results});

  FAQDetailsResponse.fromJson(Map<String, dynamic> json) {
    resultsCount = json['results_count'];
    message = json['message'];
    status = json['status'];
    if (json['results'] != null) {
      results = <FAQItem>[];
      json['results'].forEach((v) {
        results!.add(FAQItem.fromJson(v));
      });
    }
  }
}

class FAQItem {
  String? id;
  String? name; // Question?
  String? description; // Answer?

  FAQItem({this.id, this.name, this.description});

  FAQItem.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name'];
    description = json['description'];
  }
}

class AboutUsResponse {
  int? resultsCount;
  String? message;
  int? status;
  List<AboutUsItem>? results;

  AboutUsResponse({this.resultsCount, this.message, this.status, this.results});

  AboutUsResponse.fromJson(Map<String, dynamic> json) {
    resultsCount = json['results_count'];
    message = json['message'];
    status = json['status'];
    if (json['results'] != null) {
      results = <AboutUsItem>[];
      json['results'].forEach((v) {
        results!.add(AboutUsItem.fromJson(v));
      });
    }
  }
}

class AboutUsItem {
  String? pageBlockId;
  String? companyId;
  String? pageBlockName;
  String? blockContentType;
  String? image;
  String? imagePositionHalfWidth;
  String? imagePositionFullWidth;
  String? description;
  String? status;

  AboutUsItem(
      {this.pageBlockId,
      this.companyId,
      this.pageBlockName,
      this.blockContentType,
      this.image,
      this.imagePositionHalfWidth,
      this.imagePositionFullWidth,
      this.description,
      this.status});

  AboutUsItem.fromJson(Map<String, dynamic> json) {
    pageBlockId = json['page_block_id']?.toString();
    companyId = json['company_id']?.toString();
    pageBlockName = json['page_block_name'];
    blockContentType = json['block_content_type'];
    image = json['image'];
    imagePositionHalfWidth = json['image_position_half_width'];
    imagePositionFullWidth = json['image_position_full_width'];
    description = json['description'];
    status = json['status'];
  }
}

class PromotionsResponse {
  int? resultsCount;
  String? message;
  int? status;
  int? totalPages;
  int? totalRecords;
  List<PromotionsItem>? results;

  PromotionsResponse(
      {this.resultsCount,
      this.message,
      this.status,
      this.totalPages,
      this.totalRecords,
      this.results});

  PromotionsResponse.fromJson(Map<String, dynamic> json) {
    resultsCount = json['results_count'];
    message = json['message'];
    status = json['status'];
    totalPages = json['total_pages'];
    totalRecords = json['total_records'];
    if (json['results'] != null) {
      results = <PromotionsItem>[];
      json['results'].forEach((v) {
        results!.add(PromotionsItem.fromJson(v));
      });
    }
  }
}

class PromotionsItem {
  String? promotionId;
  String? name; // Added name field
  String? title;
  String? displayName;
  String? description;
  String? image;
  String? fromDate;
  String? toDate;
  String? promotionPrice;
  String? price;
  String? divisionId;
  String? groupId;
  String? subGroupId;
  String? subSubGroupId;
  List<PromotionProduct>? products;

  PromotionsItem(
      {this.promotionId,
      this.title,
      this.displayName,
      this.description,
      this.image,
      this.fromDate,
      this.toDate,
      this.promotionPrice,
      this.price,
      this.divisionId,
      this.groupId,
      this.subGroupId,
      this.subSubGroupId,
      this.name, // Added name field
      this.products});

  PromotionsItem.fromJson(Map<String, dynamic> json) {
    promotionId = json['promotion_id']?.toString();
    title = json['title'];
    displayName = json['display_name'];
    description = json['description'];
    image = json['image'];
    fromDate = json['from_date'];
    toDate = json['to_date'];
    promotionPrice = json['promotion_price']?.toString();
    price = json['price']?.toString();
    divisionId = json['division_id']?.toString();
    groupId = json['group_id']?.toString();
    subGroupId = json['sub_group_id']?.toString();
    subSubGroupId = json['sub_sub_group_id']?.toString();
    name = json['name']; // Map name field
    if (json['products'] != null) {
      products = <PromotionProduct>[];
      json['products'].forEach((v) {
        products!.add(PromotionProduct.fromJson(v));
      });
    }
  }
}

class PromotionProduct {
  String? productId;

  PromotionProduct({this.productId});

  PromotionProduct.fromJson(Map<String, dynamic> json) {
    productId = json['product_id']?.toString();
  }
}

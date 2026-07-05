class WishlistCategoriesResponse {
  int? status;
  String? message;
  List<WishlistCategory?>? results;

  WishlistCategoriesResponse({this.status, this.message, this.results});

  factory WishlistCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return WishlistCategoriesResponse(
      status: json['status'],
      message: json['message'],
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? WishlistCategory.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class WishlistCategory {
  String? categoryId;
  String? categoryName;
  String? productAdded; // "Yes" or "No"
  bool isSelected = false; // UI state

  WishlistCategory({
    this.categoryId,
    this.categoryName,
    this.productAdded,
  }) {
    isSelected = productAdded == "Yes";
  }

  factory WishlistCategory.fromJson(Map<String, dynamic> json) {
    return WishlistCategory(
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString(),
      productAdded: json['product_added']?.toString(),
    );
  }
}

class AddToWishlistResponse {
  int? status;
  String? message;
  String? successMessage;

  AddToWishlistResponse({this.status, this.message, this.successMessage});

  factory AddToWishlistResponse.fromJson(Map<String, dynamic> json) {
    return AddToWishlistResponse(
      status: json['status'],
      message: json['message'],
      successMessage: json['success_message']?.toString(),
    );
  }
}

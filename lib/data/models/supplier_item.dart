class SupplierItem {
  String? image;
  String? externalLink;
  String? brandid;

  SupplierItem({this.image, this.externalLink, this.brandid});

  factory SupplierItem.fromJson(Map<String, dynamic> json) {
    return SupplierItem(
      image: json['image']?.toString(),
      externalLink: json['external_link']?.toString(),
      brandid: json['brand_id']?.toString(),
    );
  }
}

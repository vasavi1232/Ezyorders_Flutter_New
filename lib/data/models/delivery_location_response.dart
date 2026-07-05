class DeliveryLocationResponse {
  int? status;
  String? message;
  List<DeliveryLocationResult?>? results;

  DeliveryLocationResponse({this.status, this.message, this.results});

  factory DeliveryLocationResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryLocationResponse(
      status: json['status'],
      message: json['message']?.toString(),
      results: json['results'] != null
          ? (json['results'] as List)
              .map((i) => i != null ? DeliveryLocationResult.fromJson(i) : null)
              .toList()
          : null,
    );
  }
}

class DeliveryLocationResult {
  String? deliveryLocationId;
  String? locationName;
  String? subLocationName;
  String? deliveryLocationCharge;

  DeliveryLocationResult({
    this.deliveryLocationId,
    this.locationName,
    this.subLocationName,
    this.deliveryLocationCharge,
  });

  factory DeliveryLocationResult.fromJson(Map<String, dynamic> json) {
    return DeliveryLocationResult(
      deliveryLocationId: json['delivery_location_id']?.toString(),
      locationName: json['location_name']?.toString(),
      subLocationName: json['sub_location_name']?.toString(),
      deliveryLocationCharge: json['delivery_location_charge']?.toString(),
    );
  }
}

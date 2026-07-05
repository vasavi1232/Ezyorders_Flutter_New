class UserEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String accessToken;
  final int? status;
  final String? message;
  final String? error;
  final String? customerId;

  UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.accessToken,
    this.status,
    this.message,
    this.error,
    this.customerId,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['customer_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      accessToken: json['access_token']?.toString() ?? '',
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? '0'),
      message: json['message']?.toString(),
      error: json['error']?.toString(),
      customerId: json['customer_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'access_token': accessToken,
      'status': status,
      'message': message,
      'error': error,
    };
  }
}

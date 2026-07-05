import '../entities/user_entity.dart';
import '../entities/companies_response.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<void> logout();

  Future<CompaniesResponse> getCompanies();
  Future<dynamic> signUp({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String receiptEmails,
    required String title,
    String customerSource = "Android",
    String deviceType = "Android",
  });
  Future<dynamic> forgotPassword(String email);
}

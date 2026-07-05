import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/companies_response.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<void> logout() async {
    // Implement logout logic
  }

  @override
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
  }) async {
    return await remoteDataSource.signUp(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      password: password,
      receiptEmails: receiptEmails,
      title: title,
      customerSource: customerSource,
      deviceType: deviceType,
    );
  }

  @override
  Future<CompaniesResponse> getCompanies() async {
    return await remoteDataSource.getCompanies();
  }

  @override
  Future<dynamic> forgotPassword(String email) async {
    return await remoteDataSource.forgotPassword(email);
  }
}

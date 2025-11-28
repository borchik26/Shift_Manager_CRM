import 'package:my_app/data/models/user.dart';
import 'package:my_app/data/services/api_service.dart';

/// Repository for authentication operations
/// ViewModels should use this instead of calling ApiService directly
class AuthRepository {
  final ApiService _apiService;

  AuthRepository({required ApiService apiService}) : _apiService = apiService;

  Future<User?> login(String username, String password) {
    return _apiService.login(username, password);
  }

  Future<void> logout() {
    return _apiService.logout();
  }
}
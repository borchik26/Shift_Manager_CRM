import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/services/api_service.dart';

/// Repository for branch operations
/// ViewModels should use this instead of calling ApiService directly
class BranchRepository {
  final ApiService _apiService;

  BranchRepository({required ApiService apiService})
      : _apiService = apiService;

  Future<List<Branch>> getBranches() {
    return _apiService.getBranches();
  }

  Future<Branch?> getBranchById(String id) {
    return _apiService.getBranchById(id);
  }

  Future<Branch> createBranch(Branch branch) {
    return _apiService.createBranch(branch);
  }

  Future<Branch> updateBranch(Branch branch) {
    return _apiService.updateBranch(branch);
  }

  Future<void> deleteBranch(String id) {
    return _apiService.deleteBranch(id);
  }
}

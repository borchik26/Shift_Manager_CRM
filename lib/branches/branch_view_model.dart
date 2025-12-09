import 'package:flutter/foundation.dart';
import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/repositories/branch_repository.dart';

/// ViewModel for managing branches list and CRUD operations
class BranchViewModel extends ChangeNotifier {
  final BranchRepository _branchRepository;

  BranchViewModel({required BranchRepository branchRepository})
      : _branchRepository = branchRepository;

  // State
  List<Branch> _branches = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Branch> get branches => List.unmodifiable(_branches);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load all branches from repository
  Future<void> loadBranches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _branches = await _branchRepository.getBranches();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Не удалось загрузить филиалы: $e';
      debugPrint('Error loading branches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new branch
  Future<bool> createBranch(String name) async {
    if (name.trim().isEmpty) {
      _errorMessage = 'Название филиала не может быть пустым';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newBranch = Branch(
        id: '', // Backend will generate UUID
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdBranch = await _branchRepository.createBranch(newBranch);
      _branches.add(createdBranch);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Не удалось создать филиал: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating branch: $e');
      return false;
    }
  }

  /// Update an existing branch
  Future<bool> updateBranch(Branch branch, String newName) async {
    if (newName.trim().isEmpty) {
      _errorMessage = 'Название филиала не может быть пустым';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedBranch = branch.copyWith(
        name: newName.trim(),
        updatedAt: DateTime.now(),
      );

      final result = await _branchRepository.updateBranch(updatedBranch);

      // Update in local list
      final index = _branches.indexWhere((b) => b.id == branch.id);
      if (index != -1) {
        _branches[index] = result;
      }

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Не удалось обновить филиал: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating branch: $e');
      return false;
    }
  }

  /// Delete a branch
  Future<bool> deleteBranch(String branchId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _branchRepository.deleteBranch(branchId);

      // Remove from local list
      _branches.removeWhere((b) => b.id == branchId);

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Не удалось удалить филиал: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting branch: $e');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

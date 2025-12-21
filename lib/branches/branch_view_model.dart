import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/repositories/branch_repository.dart';

/// ViewModel for managing branches list and CRUD operations
class BranchViewModel extends ChangeNotifier {
  final BranchRepository _branchRepository;

  BranchViewModel({required BranchRepository branchRepository})
      : _branchRepository = branchRepository;

  AsyncValue<List<Branch>> _branchesState = const AsyncLoading();
  AsyncValue<void> _operationState = const AsyncData(null);

  AsyncValue<List<Branch>> get branchesState => _branchesState;
  AsyncValue<void> get operationState => _operationState;

  /// Load all branches from repository
  Future<void> loadBranches() async {
    _branchesState = const AsyncLoading();
    notifyListeners();

    try {
      final branches = await _branchRepository.getBranches();
      _branchesState = AsyncData(branches);
    } catch (e) {
      _branchesState = AsyncError('Не удалось загрузить филиалы: $e');
      debugPrint('Error loading branches: $e');
    }
    notifyListeners();
  }

  /// Create a new branch
  Future<bool> createBranch(String name) async {
    if (name.trim().isEmpty) {
      _operationState = const AsyncError('Название филиала не может быть пустым');
      notifyListeners();
      return false;
    }

    _operationState = const AsyncLoading();
    notifyListeners();

    try {
      final newBranch = Branch(
        id: '',
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdBranch = await _branchRepository.createBranch(newBranch);
      final currentBranches = _branchesState.dataOrNull ?? [];
      _branchesState = AsyncData([...currentBranches, createdBranch]);
      _operationState = const AsyncData(null);
      notifyListeners();
      return true;
    } catch (e) {
      _operationState = AsyncError('Не удалось создать филиал: $e');
      notifyListeners();
      debugPrint('Error creating branch: $e');
      return false;
    }
  }

  /// Update an existing branch
  Future<bool> updateBranch(Branch branch, String newName) async {
    if (newName.trim().isEmpty) {
      _operationState = const AsyncError('Название филиала не может быть пустым');
      notifyListeners();
      return false;
    }

    _operationState = const AsyncLoading();
    notifyListeners();

    try {
      final updatedBranch = branch.copyWith(
        name: newName.trim(),
        updatedAt: DateTime.now(),
      );

      final result = await _branchRepository.updateBranch(updatedBranch);
      final currentBranches = _branchesState.dataOrNull ?? [];
      final index = currentBranches.indexWhere((b) => b.id == branch.id);
      if (index != -1) {
        final updatedList = [...currentBranches];
        updatedList[index] = result;
        _branchesState = AsyncData(updatedList);
      }

      _operationState = const AsyncData(null);
      notifyListeners();
      return true;
    } catch (e) {
      _operationState = AsyncError('Не удалось обновить филиал: $e');
      notifyListeners();
      debugPrint('Error updating branch: $e');
      return false;
    }
  }

  /// Delete a branch
  Future<bool> deleteBranch(String branchId) async {
    _operationState = const AsyncLoading();
    notifyListeners();

    try {
      await _branchRepository.deleteBranch(branchId);
      final currentBranches = _branchesState.dataOrNull ?? [];
      _branchesState = AsyncData(currentBranches.where((b) => b.id != branchId).toList());
      _operationState = const AsyncData(null);
      notifyListeners();
      return true;
    } catch (e) {
      _operationState = AsyncError('Не удалось удалить филиал: $e');
      notifyListeners();
      debugPrint('Error deleting branch: $e');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _operationState = const AsyncData(null);
    notifyListeners();
  }
}

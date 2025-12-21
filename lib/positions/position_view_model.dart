import 'package:flutter/foundation.dart';
import 'package:my_app/core/utils/async_value.dart';
import 'package:my_app/data/models/position.dart';
import 'package:my_app/data/repositories/position_repository.dart';

/// ViewModel for managing positions list and CRUD operations
class PositionViewModel extends ChangeNotifier {
  PositionViewModel({required PositionRepository positionRepository})
      : _positionRepository = positionRepository;

  final PositionRepository _positionRepository;

  AsyncValue<List<Position>> _positionsState = const AsyncLoading();
  AsyncValue<void> _operationState = const AsyncData(null);

  AsyncValue<List<Position>> get positionsState => _positionsState;
  AsyncValue<void> get operationState => _operationState;

  Future<void> loadPositions() async {
    _positionsState = const AsyncLoading();
    notifyListeners();

    try {
      final positions = await _positionRepository.getPositions();
      _positionsState = AsyncData(positions);
    } catch (e) {
      _positionsState = AsyncError('Не удалось загрузить должности: $e');
      debugPrint('Error loading positions: $e');
    }
    notifyListeners();
  }

  Future<bool> createPosition(String name, double hourlyRate) async {
    if (name.trim().isEmpty) {
      _operationState = const AsyncError('Название должности не может быть пустым');
      notifyListeners();
      return false;
    }
    if (hourlyRate <= 0) {
      _operationState = const AsyncError('Ставка должна быть больше 0');
      notifyListeners();
      return false;
    }

    _operationState = const AsyncLoading();
    notifyListeners();

    try {
      final position = Position(
        id: '',
        name: name.trim(),
        hourlyRate: hourlyRate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _positionRepository.createPosition(position);
      final currentPositions = _positionsState.dataOrNull ?? [];
      _positionsState = AsyncData([...currentPositions, created]);
      _operationState = const AsyncData(null);
      notifyListeners();
      return true;
    } catch (e) {
      _operationState = AsyncError('Не удалось создать должность: $e');
      notifyListeners();
      debugPrint('Error creating position: $e');
      return false;
    }
  }

  Future<bool> updatePosition(Position position, String newName, double newRate) async {
    if (newName.trim().isEmpty) {
      _operationState = const AsyncError('Название должности не может быть пустым');
      notifyListeners();
      return false;
    }
    if (newRate <= 0) {
      _operationState = const AsyncError('Ставка должна быть больше 0');
      notifyListeners();
      return false;
    }

    _operationState = const AsyncLoading();
    notifyListeners();

    try {
      final updated = position.copyWith(
        name: newName.trim(),
        hourlyRate: newRate,
        updatedAt: DateTime.now(),
      );

      final result = await _positionRepository.updatePosition(updated);
      final currentPositions = _positionsState.dataOrNull ?? [];
      final index = currentPositions.indexWhere((p) => p.id == position.id);
      if (index != -1) {
        final updatedList = [...currentPositions];
        updatedList[index] = result;
        _positionsState = AsyncData(updatedList);
      }

      _operationState = const AsyncData(null);
      notifyListeners();
      return true;
    } catch (e) {
      _operationState = AsyncError('Не удалось обновить должность: $e');
      notifyListeners();
      debugPrint('Error updating position: $e');
      return false;
    }
  }

  Future<bool> deletePosition(String id) async {
    _operationState = const AsyncLoading();
    notifyListeners();

    try {
      await _positionRepository.deletePosition(id);
      final currentPositions = _positionsState.dataOrNull ?? [];
      _positionsState = AsyncData(currentPositions.where((p) => p.id != id).toList());
      _operationState = const AsyncData(null);
      notifyListeners();
      return true;
    } catch (e) {
      _operationState = AsyncError('Не удалось удалить должность: $e');
      notifyListeners();
      debugPrint('Error deleting position: $e');
      return false;
    }
  }

  void clearError() {
    _operationState = const AsyncData(null);
    notifyListeners();
  }
}

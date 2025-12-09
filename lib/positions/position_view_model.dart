import 'package:flutter/foundation.dart';
import 'package:my_app/data/models/position.dart';
import 'package:my_app/data/repositories/position_repository.dart';

/// ViewModel for managing positions list and CRUD operations
class PositionViewModel extends ChangeNotifier {
  PositionViewModel({required PositionRepository positionRepository})
      : _positionRepository = positionRepository;

  final PositionRepository _positionRepository;

  List<Position> _positions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Position> get positions => List.unmodifiable(_positions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadPositions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _positions = await _positionRepository.getPositions();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Не удалось загрузить должности: $e';
      debugPrint('Error loading positions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPosition(String name, double hourlyRate) async {
    if (name.trim().isEmpty) {
      _errorMessage = 'Название должности не может быть пустым';
      notifyListeners();
      return false;
    }
    if (hourlyRate <= 0) {
      _errorMessage = 'Ставка должна быть больше 0';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = Position(
        id: '', // Backend generates UUID
        name: name.trim(),
        hourlyRate: hourlyRate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _positionRepository.createPosition(position);
      _positions.add(created);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Не удалось создать должность: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating position: $e');
      return false;
    }
  }

  Future<bool> updatePosition(Position position, String newName, double newRate) async {
    if (newName.trim().isEmpty) {
      _errorMessage = 'Название должности не может быть пустым';
      notifyListeners();
      return false;
    }
    if (newRate <= 0) {
      _errorMessage = 'Ставка должна быть больше 0';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = position.copyWith(
        name: newName.trim(),
        hourlyRate: newRate,
        updatedAt: DateTime.now(),
      );

      final result = await _positionRepository.updatePosition(updated);
      final index = _positions.indexWhere((p) => p.id == position.id);
      if (index != -1) {
        _positions[index] = result;
      }

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Не удалось обновить должность: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating position: $e');
      return false;
    }
  }

  Future<bool> deletePosition(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _positionRepository.deletePosition(id);
      _positions.removeWhere((p) => p.id == id);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Не удалось удалить должность: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting position: $e');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

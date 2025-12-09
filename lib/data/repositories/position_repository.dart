import 'package:my_app/data/models/position.dart';
import 'package:my_app/data/services/api_service.dart';

/// Repository for position operations
/// ViewModels should use this instead of calling ApiService directly
class PositionRepository {
  final ApiService _apiService;

  PositionRepository({required ApiService apiService})
      : _apiService = apiService;

  Future<List<Position>> getPositions() {
    return _apiService.getPositions();
  }

  Future<Position?> getPositionById(String id) {
    return _apiService.getPositionById(id);
  }

  Future<Position> createPosition(Position position) {
    return _apiService.createPosition(position);
  }

  Future<Position> updatePosition(Position position) {
    return _apiService.updatePosition(position);
  }

  Future<void> deletePosition(String id) {
    return _apiService.deletePosition(id);
  }
}

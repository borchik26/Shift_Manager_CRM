import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/services/api_service.dart';

/// Repository for shift operations
/// ViewModels should use this instead of calling ApiService directly
class ShiftRepository {
  final ApiService _apiService;

  ShiftRepository({required ApiService apiService}) : _apiService = apiService;

  Future<List<Shift>> getShifts({DateTime? startDate, DateTime? endDate}) {
    return _apiService.getShifts(startDate: startDate, endDate: endDate);
  }

  Future<List<Shift>> getShiftsByEmployee(String employeeId) {
    return _apiService.getShiftsByEmployee(employeeId);
  }

  Future<Shift?> getShiftById(String id) {
    return _apiService.getShiftById(id);
  }

  Future<Shift> createShift(Shift shift) {
    return _apiService.createShift(shift);
  }

  Future<Shift> updateShift(Shift shift) {
    return _apiService.updateShift(shift);
  }

  Future<void> deleteShift(String id) {
    return _apiService.deleteShift(id);
  }
}
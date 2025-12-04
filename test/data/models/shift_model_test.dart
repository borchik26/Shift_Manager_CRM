import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/models/shift.dart';

void main() {
  group('Shift Model', () {
    final testShift = Shift(
      id: 'shift_1',
      employeeId: 'emp_1',
      location: 'ТЦ Мега',
      startTime: DateTime.parse('2023-12-25T09:00:00.000Z'),
      endTime: DateTime.parse('2023-12-25T18:00:00.000Z'),
      status: 'confirmed',
      notes: 'Важная смена',
      isNightShift: false,
      roleTitle: 'Менеджер',
      hourlyRate: 840.0,
    );

    const testJson = {
      'id': 'shift_1',
      'employee_id': 'emp_1',
      'location': 'ТЦ Мега',
      'start_time': '2023-12-25T09:00:00.000Z',
      'end_time': '2023-12-25T18:00:00.000Z',
      'status': 'confirmed',
      'notes': 'Важная смена',
      'is_night_shift': false,
      'role_title': 'Менеджер',
      'hourly_rate': 840.0,
    };

    test('creates Shift from JSON correctly', () {
      final shift = Shift.fromJson(testJson);
      
      expect(shift.id, equals('shift_1'));
      expect(shift.employeeId, equals('emp_1'));
      expect(shift.location, equals('ТЦ Мега'));
      expect(shift.startTime, equals(DateTime.parse('2023-12-25T09:00:00.000Z')));
      expect(shift.endTime, equals(DateTime.parse('2023-12-25T18:00:00.000Z')));
      expect(shift.status, equals('confirmed'));
      expect(shift.notes, equals('Важная смена'));
      expect(shift.isNightShift, isFalse);
      expect(shift.roleTitle, equals('Менеджер'));
      expect(shift.hourlyRate, equals(840.0));
    });

    test('converts Shift to JSON correctly', () {
      final json = testShift.toJson();
      
      expect(json['id'], equals('shift_1'));
      expect(json['employee_id'], equals('emp_1'));
      expect(json['location'], equals('ТЦ Мега'));
      expect(json['start_time'], equals('2023-12-25T09:00:00.000Z'));
      expect(json['end_time'], equals('2023-12-25T18:00:00.000Z'));
      expect(json['status'], equals('confirmed'));
      expect(json['notes'], equals('Важная смена'));
      expect(json['is_night_shift'], isFalse);
      expect(json['role_title'], equals('Менеджер'));
      expect(json['hourly_rate'], equals(840.0));
    });

    test('duration getter calculates correct duration', () {
      final duration = testShift.duration;
      
      expect(duration.inHours, equals(9));
      expect(duration.inMinutes, equals(540));
    });

    test('copyWith creates new instance with updated fields', () {
      final updatedShift = testShift.copyWith(
        status: 'pending',
        notes: 'Обновленная смена',
      );
      
      expect(updatedShift.id, equals(testShift.id));
      expect(updatedShift.employeeId, equals(testShift.employeeId));
      expect(updatedShift.location, equals(testShift.location));
      expect(updatedShift.status, equals('pending'));
      expect(updatedShift.notes, equals('Обновленная смена'));
      expect(updatedShift.startTime, equals(testShift.startTime));
      expect(updatedShift.endTime, equals(testShift.endTime));
    });

    test('fromJson/toJson roundtrip produces same object', () {
      final shiftFromJson = Shift.fromJson(testShift.toJson());
      
      expect(shiftFromJson.id, equals(testShift.id));
      expect(shiftFromJson.employeeId, equals(testShift.employeeId));
      expect(shiftFromJson.location, equals(testShift.location));
      expect(shiftFromJson.startTime, equals(testShift.startTime));
      expect(shiftFromJson.endTime, equals(testShift.endTime));
      expect(shiftFromJson.status, equals(testShift.status));
      expect(shiftFromJson.notes, equals(testShift.notes));
      expect(shiftFromJson.isNightShift, equals(testShift.isNightShift));
      expect(shiftFromJson.roleTitle, equals(testShift.roleTitle));
      expect(shiftFromJson.hourlyRate, equals(testShift.hourlyRate));
    });

    test('handles JSON with optional fields missing', () {
      const minimalJson = {
        'id': 'shift_1',
        'employee_id': 'emp_1',
        'location': 'ТЦ Мега',
        'start_time': '2023-12-25T09:00:00.000Z',
        'end_time': '2023-12-25T18:00:00.000Z',
        'status': 'confirmed',
        'hourly_rate': 400.0,
      };
      
      final shift = Shift.fromJson(minimalJson);
      
      expect(shift.notes, isNull);
      expect(shift.isNightShift, isFalse); // Default value
      expect(shift.employeePreferences, isNull);
      expect(shift.roleTitle, isNull);
      expect(shift.hourlyRate, equals(400.0));
    });

    test('handles JSON with null hourly_rate', () {
      const jsonWithoutHourlyRate = {
        'id': 'shift_1',
        'employee_id': 'emp_1',
        'location': 'ТЦ Мега',
        'start_time': '2023-12-25T09:00:00.000Z',
        'end_time': '2023-12-25T18:00:00.000Z',
        'status': 'confirmed',
      };
      
      final shift = Shift.fromJson(jsonWithoutHourlyRate);
      
      expect(shift.hourlyRate, equals(400.0)); // Default value
    });

    test('handles JSON with numeric hourly_rate', () {
      const jsonWithIntHourlyRate = {
        'id': 'shift_1',
        'employee_id': 'emp_1',
        'location': 'ТЦ Мега',
        'start_time': '2023-12-25T09:00:00.000Z',
        'end_time': '2023-12-25T18:00:00.000Z',
        'status': 'confirmed',
        'hourly_rate': 500, // int instead of double
      };
      
      final shift = Shift.fromJson(jsonWithIntHourlyRate);
      
      expect(shift.hourlyRate, equals(500.0));
    });

    test('night shift detection', () {
      final nightShift = testShift.copyWith(
        startTime: DateTime.parse('2023-12-25T22:00:00.000Z'),
        endTime: DateTime.parse('2023-12-26T06:00:00.000Z'),
        isNightShift: true,
      );
      
      expect(nightShift.isNightShift, isTrue);
    });

    test('duration calculation for overnight shift', () {
      final overnightShift = Shift(
        id: 'shift_overnight',
        employeeId: 'emp_1',
        location: 'ТЦ Мега',
        startTime: DateTime.parse('2023-12-25T22:00:00.000Z'),
        endTime: DateTime.parse('2023-12-26T06:00:00.000Z'),
        status: 'confirmed',
        hourlyRate: 840.0,
      );
      
      expect(overnightShift.duration.inHours, equals(8));
    });

    test('equality check', () {
      final shift1 = Shift(
        id: '1',
        employeeId: 'emp_1',
        location: 'ТЦ Мега',
        startTime: DateTime.parse('2023-12-25T09:00:00.000Z'),
        endTime: DateTime.parse('2023-12-25T18:00:00.000Z'),
        status: 'confirmed',
        hourlyRate: 400.0,
      );
      
      final shift2 = Shift(
        id: '1',
        employeeId: 'emp_1',
        location: 'ТЦ Мега',
        startTime: DateTime.parse('2023-12-25T09:00:00.000Z'),
        endTime: DateTime.parse('2023-12-25T18:00:00.000Z'),
        status: 'confirmed',
        hourlyRate: 400.0,
      );
      
      final shift3 = Shift(
        id: '2',
        employeeId: 'emp_1',
        location: 'ТЦ Мега',
        startTime: DateTime.parse('2023-12-25T09:00:00.000Z'),
        endTime: DateTime.parse('2023-12-25T18:00:00.000Z'),
        status: 'confirmed',
        hourlyRate: 400.0,
      );

      expect(shift1, equals(shift2));
      expect(shift1, isNot(equals(shift3))); // shift3 has different id
    });
  });
}
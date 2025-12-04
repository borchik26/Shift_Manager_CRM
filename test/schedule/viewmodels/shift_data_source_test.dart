import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:my_app/schedule/viewmodels/shift_data_source.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  group('ShiftDataSource', () {
    late ShiftDataSource dataSource;
    late List<ShiftModel> shifts;

    setUp(() {
      shifts = [
        ShiftModel(
          id: '1',
          employeeId: '1',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 8)),
          roleTitle: 'Администратор',
          location: 'Центр',
          color: Colors.blue,
          hourlyRate: 840.0,
        ),
        ShiftModel(
          id: '2',
          employeeId: '2',
          startTime: DateTime.now().add(const Duration(hours: 12)),
          endTime: DateTime.now().add(const Duration(hours: 20)),
          roleTitle: 'Кассир',
          location: 'ТЦ Мега',
          color: Colors.orange,
          hourlyRate: 600.0,
        ),
      ];

      final resources = [
        CalendarResource(
          id: '1',
          displayName: 'Иван Иванов',
          color: Colors.blue,
        ),
        CalendarResource(
          id: '2',
          displayName: 'Петр Петров',
          color: Colors.orange,
        ),
      ];

      dataSource = ShiftDataSource(shifts, resources: resources);
    });

    test('getStartTime returns correct start time', () {
      // Act
      final result = dataSource.getStartTime(0);

      // Assert
      expect(result, shifts[0].startTime);
    });

    test('getEndTime returns correct end time', () {
      // Act
      final result = dataSource.getEndTime(0);

      // Assert
      expect(result, shifts[0].endTime);
    });

    test('getSubject returns correct role title', () {
      // Act
      final result = dataSource.getSubject(0);

      // Assert
      expect(result, shifts[0].roleTitle);
    });

    test('getColor returns correct color', () {
      // Act
      final result = dataSource.getColor(0);

      // Assert
      expect(result, shifts[0].color);
    });

    test('getResourceIds returns correct employee ID', () {
      // Act
      final result = dataSource.getResourceIds(0);

      // Assert
      expect(result, ['1']);
    });

    test('getNotes returns correct location', () {
      // Act
      final result = dataSource.getNotes(0);

      // Assert
      expect(result, shifts[0].location);
    });

    test('getId returns correct shift ID', () {
      // Act
      final result = dataSource.getId(0);

      // Assert
      expect(result, shifts[0].id);
    });

    test('convertAppointmentToObject returns original shift', () {
      // Arrange
      final shift = ShiftModel(
        id: 'test',
        employeeId: 'test-employee',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 8)),
        roleTitle: 'Тест',
        location: 'Тест',
        color: Colors.blue,
        hourlyRate: 500.0,
      );

      // Act
      final result = dataSource.convertAppointmentToObject(
        shift,
        Appointment(
          startTime: shift.startTime,
          endTime: shift.endTime,
        ),
      );

      // Assert
      expect(result, shift);
    });

    test('handles empty shifts list', () {
      // Arrange
      final emptyDataSource = ShiftDataSource([], resources: []);

      // Act & Assert
      expect(() => emptyDataSource.getStartTime(0), throwsA(isA<RangeError>()));
      expect(() => emptyDataSource.getEndTime(0), throwsA(isA<RangeError>()));
      expect(() => emptyDataSource.getSubject(0), throwsA(isA<RangeError>()));
      expect(() => emptyDataSource.getColor(0), throwsA(isA<RangeError>()));
      expect(() => emptyDataSource.getResourceIds(0), throwsA(isA<RangeError>()));
      expect(() => emptyDataSource.getNotes(0), throwsA(isA<RangeError>()));
      expect(() => emptyDataSource.getId(0), throwsA(isA<RangeError>()));
    });

    test('handles index out of bounds gracefully', () {
      // Act & Assert
      expect(() => dataSource.getStartTime(-1), throwsA(isA<RangeError>()));
      expect(() => dataSource.getEndTime(999), throwsA(isA<RangeError>()));
      expect(() => dataSource.getSubject(-1), throwsA(isA<RangeError>()));
      expect(() => dataSource.getColor(-1), throwsA(isA<RangeError>()));
      expect(() => dataSource.getResourceIds(-1), throwsA(isA<RangeError>()));
      expect(() => dataSource.getNotes(-1), throwsA(isA<RangeError>()));
      expect(() => dataSource.getId(-1), throwsA(isA<RangeError>()));
    });

    group('Resource Management', () {
      test('resources are properly initialized', () {
        // Act
        final result = dataSource.resources!;

        // Assert
        expect(result.length, 2);
        expect(result[0].id, '1');
        expect(result[0].displayName, 'Иван Иванов');
        expect(result[1].id, '2');
        expect(result[1].displayName, 'Петр Петров');
      });

      test('resources are properly assigned', () {
        // Arrange
        final newResources = [
          CalendarResource(
            id: '4',
            displayName: 'Новый сотрудник',
            color: Colors.red,
          ),
        ];

        // Act
        dataSource.resources = newResources;

        // Assert
        expect(dataSource.resources!.length, 1);
        expect(dataSource.resources![0].id, '4');
        expect(dataSource.resources![0].displayName, 'Новый сотрудник');
      });
    });
  });
}
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/models/employee.dart';

/// Adapter to convert Shift model to Syncfusion Appointment
class ShiftAdapter {
  /// Convert Shift to Appointment for Syncfusion Calendar
  static Appointment toAppointment(
    Shift shift, {
    Employee? employee,
    Color? color,
  }) {
    return Appointment(
      id: shift.id,
      startTime: shift.startTime,
      endTime: shift.endTime,
      subject: employee?.fullName ?? 'Shift',
      notes: shift.notes,
      color: color ?? _getColorForStatus(shift.status),
      resourceIds: employee != null ? [employee.id] : null,
      isAllDay: false,
    );
  }

  /// Convert list of Shifts to list of Appointments
  static List<Appointment> toAppointments(
    List<Shift> shifts, {
    Map<String, Employee>? employeeMap,
  }) {
    return shifts.map((shift) {
      final employee = employeeMap?[shift.employeeId];
      return toAppointment(shift, employee: employee);
    }).toList();
  }

  /// Get color based on shift status
  static Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'pending':
        return Colors.amber;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// Create CalendarDataSource from shifts
  static ShiftDataSource createDataSource(
    List<Shift> shifts, {
    Map<String, Employee>? employeeMap,
    List<CalendarResource>? resources,
  }) {
    final appointments = toAppointments(shifts, employeeMap: employeeMap);
    return ShiftDataSource(appointments, resources);
  }

  /// Create CalendarResource from Employee
  static CalendarResource employeeToResource(Employee employee) {
    return CalendarResource(
      id: employee.id,
      displayName: employee.fullName,
      color: _getColorForEmployee(employee),
      image: employee.avatarUrl != null
          ? NetworkImage(employee.avatarUrl!)
          : null,
    );
  }

  /// Get color for employee (for resource view)
  static Color _getColorForEmployee(Employee employee) {
    final hash = employee.id.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }
}

/// Custom CalendarDataSource for Syncfusion Calendar
class ShiftDataSource extends CalendarDataSource {
  ShiftDataSource(
    List<Appointment> appointments,
    List<CalendarResource>? resources,
  ) {
    this.appointments = appointments;
    this.resources = resources;
  }
}
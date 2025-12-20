import 'package:flutter/material.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ShiftDataSource extends CalendarDataSource {
  ShiftDataSource(
    List<ShiftModel> source, {
    List<CalendarResource>? resources,
  }) {
    appointments = source;
    if (resources != null) {
      this.resources = resources;
    }
  }

  @override
  DateTime getStartTime(int index) {
    return _getShiftData(index).startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return _getShiftData(index).endTime;
  }

  @override
  String getSubject(int index) {
    return _getShiftData(index).roleTitle;
  }

  @override
  Color getColor(int index) {
    return _getShiftData(index).color;
  }

  @override
  List<Object> getResourceIds(int index) {
    final employeeId = _getShiftData(index).employeeId;
    // Return 'unassigned' if employeeId is null (shouldn't happen with our logic)
    return [employeeId ?? 'unassigned'];
  }

  @override
  String? getNotes(int index) {
    return _getShiftData(index).location;
  }

  @override
  Object? getId(int index) {
    return _getShiftData(index).id;
  }

  @override
  Object? convertAppointmentToObject(
    Object? customData,
    Appointment appointment,
  ) {
    // Return the original ShiftModel object for drag-and-drop operations
    return customData;
  }

  ShiftModel _getShiftData(int index) {
    final dynamic appointment = appointments![index];
    return appointment as ShiftModel;
  }
}
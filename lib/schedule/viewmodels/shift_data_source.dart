import 'package:flutter/material.dart';
import 'package:my_app/schedule/models/shift_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ShiftDataSource extends CalendarDataSource {
  ShiftDataSource(List<ShiftModel> source) {
    appointments = source;
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
    return [_getShiftData(index).employeeId];
  }

  @override
  String? getNotes(int index) {
    return _getShiftData(index).location;
  }

  @override
  Object? getId(int index) {
    return _getShiftData(index).id;
  }

  ShiftModel _getShiftData(int index) {
    final dynamic appointment = appointments![index];
    return appointment as ShiftModel;
  }
}
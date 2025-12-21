import 'dart:async' as dart_async;

import 'package:flutter/foundation.dart';
import 'package:my_app/audit_logs/models/audit_log_constants.dart';
import 'package:my_app/core/utils/exceptions/app_exceptions.dart' as app;
import 'package:my_app/data/models/shift.dart';
import 'package:my_app/data/services/base_supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShiftService extends BaseSupabaseService<Shift> {
  @override
  String get tableName => 'shifts';

  @override
  Shift fromJson(Map<String, dynamic> json) => Shift.fromJson(json);

  @override
  Map<String, dynamic> toJson(Shift shift) => shift.toJson();

  Future<List<Shift>> getShifts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeWithResilience(() async {
      var query = Supabase.instance.client.from(tableName).select('*');

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('end_time', endDate.toIso8601String());
      }

      final response = await query.order('start_time', ascending: true);
      return (response as List).map((json) => fromJson(json)).toList();
    });
  }

  Future<List<Shift>> getShiftsByEmployee(String employeeId) async {
    return executeWithResilience(() async {
      final response = await Supabase.instance.client
          .from(tableName)
          .select('*')
          .eq('employee_id', employeeId)
          .order('start_time', ascending: true);

      return (response as List).map((json) => fromJson(json)).toList();
    });
  }

  Future<Shift> createShift(Shift shift) async {
    try {
      final createdShift = await executeWithResilience(() async {
        final insertData = shift.toJson();
        insertData.remove('id');
        insertData.remove('status');

        final response = await Supabase.instance.client
            .from(tableName)
            .insert(insertData)
            .select('*')
            .single();

        return fromJson(response);
      });

      _logAuditEvent(
        actionType: AuditLogActionType.create,
        entityType: AuditLogEntityType.shift,
        entityId: createdShift.id,
        description:
            'Создана смена для ${createdShift.roleTitle} at ${createdShift.location}',
        changesAfter: createdShift.toJson(),
        metadata: {'source': 'schedule'},
      );

      return createdShift;
    } on PostgrestException catch (e) {
      if (e.message.contains('overlaps')) {
        throw app.ConflictException(
          'Смена пересекается с существующей сменой сотрудника',
          e,
        );
      }
      handleError(e, 'создания смены');
    }
  }

  Future<Shift> updateShift(Shift shift) async {
    try {
      final oldShift = await getById(shift.id);

      final updatedShift = await executeWithResilience(() async {
        final response = await Supabase.instance.client
            .from(tableName)
            .update(shift.toJson())
            .eq('id', shift.id)
            .select('*')
            .single();

        return fromJson(response);
      });

      _logAuditEvent(
        actionType: AuditLogActionType.update,
        entityType: AuditLogEntityType.shift,
        entityId: updatedShift.id,
        description: 'Обновление смены',
        changesBefore: oldShift?.toJson(),
        changesAfter: updatedShift.toJson(),
        metadata: {'source': 'schedule'},
      );

      return updatedShift;
    } on PostgrestException catch (e) {
      if (e.message.contains('overlaps')) {
        throw app.ConflictException(
          'Смена пересекается с существующей сменой сотрудника',
          e,
        );
      }
      handleError(e, 'обновления смены');
    }
  }

  Future<void> deleteShift(String id) async {
    final shift = await getById(id);

    await executeWithResilience(() async {
      await Supabase.instance.client.from(tableName).delete().eq('id', id);
    });

    _logAuditEvent(
      actionType: AuditLogActionType.delete,
      entityType: AuditLogEntityType.shift,
      entityId: id,
      description: 'Удаление смены',
      changesBefore: shift?.toJson(),
      metadata: {'source': 'schedule'},
    );
  }

  void _logAuditEvent({
    required String actionType,
    required String entityType,
    String? entityId,
    String? description,
    Map<String, dynamic>? changesBefore,
    Map<String, dynamic>? changesAfter,
    Map<String, dynamic>? metadata,
  }) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    dart_async.unawaited(
      Supabase.instance.client
          .rpc(
            'log_audit_event',
            params: {
              'p_user_id': currentUser.id,
              'p_user_email': currentUser.email ?? 'unknown',
              'p_action_type': actionType,
              'p_entity_type': entityType,
              'p_user_name': currentUser.userMetadata?['full_name'],
              'p_user_role': currentUser.userMetadata?['role'] ?? 'employee',
              'p_entity_id': entityId,
              'p_status': 'success',
              'p_description': description ?? '$actionType $entityType',
              'p_changes': changesBefore != null && changesAfter != null
                  ? {'before': changesBefore, 'after': changesAfter}
                  : (changesAfter ?? changesBefore),
              'p_metadata': metadata,
            },
          )
          .catchError((e) {
            debugPrint('Audit log error: $e');
          }),
    );
  }
}

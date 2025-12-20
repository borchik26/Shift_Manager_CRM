import 'package:my_app/core/utils/exceptions/app_exceptions.dart' as app;
import 'package:my_app/data/models/position.dart';
import 'package:my_app/data/services/base_supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PositionService extends BaseSupabaseService<Position> {
  @override
  String get tableName => 'positions';

  @override
  Position fromJson(Map<String, dynamic> json) => Position.fromJson(json);

  @override
  Map<String, dynamic> toJson(Position position) => position.toJson();

  Future<List<Position>> getPositions() async {
    return executeWithResilience(() async {
      final response = await Supabase.instance.client
          .from(tableName)
          .select()
          .order('name', ascending: true);

      return (response as List).map((json) => fromJson(json)).toList();
    });
  }

  Future<Position> createPosition(Position position) async {
    try {
      return await executeWithResilience(() async {
        final insertData = position.toJson()..remove('id');

        final response = await Supabase.instance.client
            .from(tableName)
            .insert(insertData)
            .select()
            .single();

        return fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw app.ConflictException(
          'Должность с таким названием уже существует',
          e,
        );
      }
      handleError(e, 'создания должности');
    }
  }

  Future<Position> updatePosition(Position position) async {
    try {
      return await executeWithResilience(() async {
        final response = await Supabase.instance.client
            .from(tableName)
            .update(position.toJson())
            .eq('id', position.id)
            .select()
            .single();

        return fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw app.ConflictException(
          'Должность с таким названием уже существует',
          e,
        );
      }
      handleError(e, 'обновления должности');
    }
  }

  Future<void> deletePosition(String id) async {
    return delete(id);
  }
}

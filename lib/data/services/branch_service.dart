import 'package:my_app/core/utils/exceptions/app_exceptions.dart' as app;
import 'package:my_app/data/models/branch.dart';
import 'package:my_app/data/services/base_supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BranchService extends BaseSupabaseService<Branch> {
  @override
  String get tableName => 'branches';

  @override
  Branch fromJson(Map<String, dynamic> json) => Branch.fromJson(json);

  @override
  Map<String, dynamic> toJson(Branch branch) => branch.toJson();

  Future<List<Branch>> getBranches() async {
    return executeWithResilience(() async {
      final response = await Supabase.instance.client
          .from(tableName)
          .select()
          .order('name', ascending: true);

      return (response as List).map((json) => fromJson(json)).toList();
    });
  }

  Future<Branch> createBranch(Branch branch) async {
    try {
      return await executeWithResilience(() async {
        final insertData = branch.toJson();
        insertData.remove('id');

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
          'Филиал с таким названием уже существует',
          e,
        );
      }
      handleError(e, 'создания филиала');
    }
  }

  Future<Branch> updateBranch(Branch branch) async {
    try {
      return await executeWithResilience(() async {
        final response = await Supabase.instance.client
            .from(tableName)
            .update(branch.toJson())
            .eq('id', branch.id)
            .select()
            .single();

        return fromJson(response);
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw app.ConflictException(
          'Филиал с таким названием уже существует',
          e,
        );
      }
      handleError(e, 'обновления филиала');
    }
  }

  Future<void> deleteBranch(String id) async {
    return delete(id);
  }
}

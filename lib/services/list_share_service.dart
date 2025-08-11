import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/list_share_model.dart';
import '../models/todo_list_model.dart';
import '../models/user_model.dart';

class ListShareService {
  static final ListShareService _instance = ListShareService._internal();
  factory ListShareService() => _instance;
  ListShareService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Share a todo list with another user
  Future<ListShare> shareList({
    required String todoListId,
    required String sharedWithUserId,
    PermissionLevel permissionLevel = PermissionLevel.view,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Verify that the current user owns the todo list
      final todoList = await _supabase
          .from('todo_lists')
          .select('user_id')
          .eq('id', todoListId)
          .eq('user_id', userId)
          .maybeSingle();

      if (todoList == null) {
        throw Exception('Todo list not found or access denied');
      }

      // Check if share already exists
      final existingShare = await _supabase
          .from('list_shares')
          .select()
          .eq('todo_list_id', todoListId)
          .eq('shared_with_user_id', sharedWithUserId)
          .maybeSingle();

      if (existingShare != null) {
        throw Exception('List is already shared with this user');
      }

      final response = await _supabase
          .from('list_shares')
          .insert({
            'todo_list_id': todoListId,
            'shared_with_user_id': sharedWithUserId,
            'permission_level': permissionLevel.value,
          })
          .select()
          .single();

      return ListShare.fromJson(response);
    } catch (error) {
      print('❌ Error sharing list: $error');
      rethrow;
    }
  }

  // Update share permissions
  Future<ListShare> updateSharePermissions({
    required String shareId,
    required PermissionLevel permissionLevel,
  }) async {
    try {
      final response = await _supabase
          .from('list_shares')
          .update({
            'permission_level': permissionLevel.value,
          })
          .eq('id', shareId)
          .select()
          .single();

      return ListShare.fromJson(response);
    } catch (error) {
      print('❌ Error updating share permissions: $error');
      rethrow;
    }
  }

  // Remove list share
  Future<void> removeListShare(String shareId) async {
    try {
      await _supabase
          .from('list_shares')
          .delete()
          .eq('id', shareId);
    } catch (error) {
      print('❌ Error removing list share: $error');
      rethrow;
    }
  }

  // Get all shares for a todo list (for list owner)
  Future<List<Map<String, dynamic>>> getListShares(String todoListId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Verify ownership
      final todoList = await _supabase
          .from('todo_lists')
          .select('user_id')
          .eq('id', todoListId)
          .eq('user_id', userId)
          .maybeSingle();

      if (todoList == null) {
        throw Exception('Todo list not found or access denied');
      }

      final response = await _supabase
          .from('list_shares')
          .select('''
            *,
            shared_with:users!shared_with_user_id(id, username, display_name, avatar_url)
          ''')
          .eq('todo_list_id', todoListId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching list shares: $error');
      rethrow;
    }
  }

  // Get todo lists shared with current user
  Future<List<Map<String, dynamic>>> getSharedWithMeLists() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('list_shares')
          .select('''
            *,
            todo_list:todo_lists!todo_list_id(
              id, name, description, color, created_at, updated_at,
              owner:users!user_id(id, username, display_name, avatar_url)
            )
          ''')
          .eq('shared_with_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching shared lists: $error');
      rethrow;
    }
  }

  // Get todo lists I've shared with others
  Future<List<Map<String, dynamic>>> getMySharedLists() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('list_shares')
          .select('''
            todo_list_id,
            todo_lists!todo_list_id(id, name, description, color, created_at, updated_at),
            count:list_shares(count)
          ''')
          .eq('todo_lists.user_id', userId)
          .order('created_at', ascending: false);

      // Group by todo list to avoid duplicates
      final Map<String, Map<String, dynamic>> uniqueLists = {};
      for (final share in response as List) {
        final todoListId = share['todo_list_id'] as String;
        if (!uniqueLists.containsKey(todoListId)) {
          uniqueLists[todoListId] = share;
        }
      }

      return uniqueLists.values.toList();
    } catch (error) {
      print('❌ Error fetching my shared lists: $error');
      rethrow;
    }
  }

  // Check user's permission level for a todo list
  Future<PermissionLevel?> getUserPermissionLevel(String todoListId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // First check if user is the owner
      final ownedList = await _supabase
          .from('todo_lists')
          .select('id')
          .eq('id', todoListId)
          .eq('user_id', userId)
          .maybeSingle();

      if (ownedList != null) {
        return PermissionLevel.edit; // Owners have full edit permissions
      }

      // Check if list is shared with user
      final share = await _supabase
          .from('list_shares')
          .select('permission_level')
          .eq('todo_list_id', todoListId)
          .eq('shared_with_user_id', userId)
          .maybeSingle();

      if (share != null) {
        return PermissionLevel.fromString(share['permission_level'] as String);
      }

      return null; // No access
    } catch (error) {
      print('❌ Error checking user permission level: $error');
      rethrow;
    }
  }

  // Get share details by ID
  Future<ListShare?> getListShare(String shareId) async {
    try {
      final response = await _supabase
          .from('list_shares')
          .select()
          .eq('id', shareId)
          .maybeSingle();

      return response != null ? ListShare.fromJson(response) : null;
    } catch (error) {
      print('❌ Error fetching list share: $error');
      rethrow;
    }
  }

  // Check if list is shared with specific user
  Future<ListShare?> getListShareForUser({
    required String todoListId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('list_shares')
          .select()
          .eq('todo_list_id', todoListId)
          .eq('shared_with_user_id', userId)
          .maybeSingle();

      return response != null ? ListShare.fromJson(response) : null;
    } catch (error) {
      print('❌ Error checking list share for user: $error');
      rethrow;
    }
  }

  // Get share statistics for user
  Future<Map<String, int>> getShareStats() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Count lists I've shared
      final sharedByMeResponse = await _supabase
          .from('list_shares')
          .select('todo_list_id')
          .eq('todo_lists.user_id', userId);

      // Count lists shared with me
      final sharedWithMeResponse = await _supabase
          .from('list_shares')
          .select('id')
          .eq('shared_with_user_id', userId);

      return {
        'shared_by_me': sharedByMeResponse.length,
        'shared_with_me': sharedWithMeResponse.length,
      };
    } catch (error) {
      print('❌ Error fetching share stats: $error');
      rethrow;
    }
  }

  // Helper method to check if user can perform action on todo list
  Future<bool> canUserPerformAction({
    required String todoListId,
    required String action, // 'view', 'comment', 'edit'
  }) async {
    try {
      final permissionLevel = await getUserPermissionLevel(todoListId);
      if (permissionLevel == null) return false;

      switch (action.toLowerCase()) {
        case 'view':
          return permissionLevel.canView;
        case 'comment':
          return permissionLevel.canComment;
        case 'edit':
          return permissionLevel.canEdit;
        default:
          return false;
      }
    } catch (error) {
      print('❌ Error checking user action permission: $error');
      return false;
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kudos_model.dart';
import '../models/user_model.dart';

class KudosService {
  static final KudosService _instance = KudosService._internal();
  factory KudosService() => _instance;
  KudosService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Send kudos
  Future<Kudos> sendKudos({
    required String toUserId,
    String? taskId,
    String? todoListId,
    String? message,
    String emoji = '👏',
  }) async {
    try {
      final fromUserId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('kudos')
          .insert({
            'from_user_id': fromUserId,
            'to_user_id': toUserId,
            'task_id': taskId,
            'todo_list_id': todoListId,
            'message': message,
            'emoji': emoji,
          })
          .select()
          .single();

      return Kudos.fromJson(response);
    } catch (error) {
      print('❌ Error sending kudos: $error');
      rethrow;
    }
  }

  // Get kudos received by current user
  Future<List<Map<String, dynamic>>> getReceivedKudos({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('kudos')
          .select('''
            *,
            from_user:users!from_user_id(id, username, display_name, avatar_url),
            task:tasks(id, title),
            todo_list:todo_lists(id, name)
          ''')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching received kudos: $error');
      rethrow;
    }
  }

  // Get kudos sent by current user
  Future<List<Map<String, dynamic>>> getSentKudos({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('kudos')
          .select('''
            *,
            to_user:users!to_user_id(id, username, display_name, avatar_url),
            task:tasks(id, title),
            todo_list:todo_lists(id, name)
          ''')
          .eq('from_user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching sent kudos: $error');
      rethrow;
    }
  }

  // Get kudos for a specific task
  Future<List<Map<String, dynamic>>> getTaskKudos(String taskId) async {
    try {
      final response = await _supabase
          .from('kudos')
          .select('''
            *,
            from_user:users!from_user_id(id, username, display_name, avatar_url)
          ''')
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching task kudos: $error');
      rethrow;
    }
  }

  // Get kudos for a specific todo list
  Future<List<Map<String, dynamic>>> getTodoListKudos(String todoListId) async {
    try {
      final response = await _supabase
          .from('kudos')
          .select('''
            *,
            from_user:users!from_user_id(id, username, display_name, avatar_url)
          ''')
          .eq('todo_list_id', todoListId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching todo list kudos: $error');
      rethrow;
    }
  }

  // Get kudos stats for user
  Future<Map<String, int>> getKudosStats([String? userId]) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser!.id;

      // Get received kudos count
      final receivedResponse = await _supabase
          .from('kudos')
          .select('id')
          .eq('to_user_id', targetUserId);

      // Get sent kudos count
      final sentResponse = await _supabase
          .from('kudos')
          .select('id')
          .eq('from_user_id', targetUserId);

      return {
        'received': receivedResponse.length,
        'sent': sentResponse.length,
      };
    } catch (error) {
      print('❌ Error fetching kudos stats: $error');
      rethrow;
    }
  }

  // Get recent kudos activity (both sent and received)
  Future<List<Map<String, dynamic>>> getRecentKudosActivity({
    int limit = 20,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('kudos')
          .select('''
            *,
            from_user:users!from_user_id(id, username, display_name, avatar_url),
            to_user:users!to_user_id(id, username, display_name, avatar_url),
            task:tasks(id, title),
            todo_list:todo_lists(id, name)
          ''')
          .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching recent kudos activity: $error');
      rethrow;
    }
  }

  // Get top emoji usage
  Future<List<Map<String, dynamic>>> getTopEmojis({int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // This would be better implemented with a database function
      // For now, fetch all kudos and count emojis client-side
      final response = await _supabase
          .from('kudos')
          .select('emoji')
          .or('from_user_id.eq.$userId,to_user_id.eq.$userId');

      final emojiCounts = <String, int>{};
      for (final kudos in response as List) {
        final emoji = kudos['emoji'] as String;
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
      }

      final sortedEntries = emojiCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedEntries
          .take(limit)
          .map((entry) => {'emoji': entry.key, 'count': entry.value})
          .toList();
    } catch (error) {
      print('❌ Error fetching top emojis: $error');
      rethrow;
    }
  }

  // Delete kudos (only if sent by current user)
  Future<void> deleteKudos(String kudosId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from('kudos')
          .delete()
          .eq('id', kudosId)
          .eq('from_user_id', userId);
    } catch (error) {
      print('❌ Error deleting kudos: $error');
      rethrow;
    }
  }

  // Check if user has already sent kudos for a specific item
  Future<bool> hasUserSentKudos({
    required String toUserId,
    String? taskId,
    String? todoListId,
  }) async {
    try {
      final fromUserId = _supabase.auth.currentUser!.id;

      final query = _supabase
          .from('kudos')
          .select('id')
          .eq('from_user_id', fromUserId)
          .eq('to_user_id', toUserId);

      if (taskId != null) {
        query.eq('task_id', taskId);
      } else if (todoListId != null) {
        query.eq('todo_list_id', todoListId);
      } else {
        query.isFilter('task_id', null).isFilter('todo_list_id', null);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (error) {
      print('❌ Error checking if user sent kudos: $error');
      rethrow;
    }
  }

  // Quick methods for common kudos types
  Future<Kudos> sendTaskKudos({
    required String toUserId,
    required String taskId,
    String? message,
    String emoji = '🎉',
  }) async {
    return sendKudos(
      toUserId: toUserId,
      taskId: taskId,
      message: message,
      emoji: emoji,
    );
  }

  Future<Kudos> sendTodoListKudos({
    required String toUserId,
    required String todoListId,
    String? message,
    String emoji = '✨',
  }) async {
    return sendKudos(
      toUserId: toUserId,
      todoListId: todoListId,
      message: message,
      emoji: emoji,
    );
  }

  Future<Kudos> sendGeneralKudos({
    required String toUserId,
    String? message,
    String emoji = '👏',
  }) async {
    return sendKudos(
      toUserId: toUserId,
      message: message,
      emoji: emoji,
    );
  }
}
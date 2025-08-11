import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new activity
  Future<Activity> createActivity({
    required String activityType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    bool isPublic = true,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('activities')
          .insert({
            'user_id': userId,
            'activity_type': activityType,
            'entity_type': entityType,
            'entity_id': entityId,
            'metadata': metadata,
            'is_public': isPublic,
          })
          .select()
          .single();

      return Activity.fromJson(response);
    } catch (error) {
      print('❌ Error creating activity: $error');
      rethrow;
    }
  }

  // Get user's own activities
  Future<List<Activity>> getUserActivities({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('activities')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Activity.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching user activities: $error');
      rethrow;
    }
  }

  // Get activity feed (public activities from friends)
  Future<List<Map<String, dynamic>>> getActivityFeed({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Get activities from friends (users who are in accepted friendships)
      final response = await _supabase
          .from('activities')
          .select('''
            *,
            users!inner(id, username, display_name, avatar_url)
          ''')
          .eq('is_public', true)
          .neq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching activity feed: $error');
      rethrow;
    }
  }

  // Get friends' activities (requires friendship relationships)
  Future<List<Map<String, dynamic>>> getFriendsActivityFeed({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Get activities from accepted friends only
      final response = await _supabase
          .from('activities')
          .select('''
            *,
            users!inner(
              id, username, display_name, avatar_url,
              friendships_requester!inner(status),
              friendships_addressee!inner(status)
            )
          ''')
          .eq('is_public', true)
          .neq('user_id', userId)
          .or('friendships_requester.addressee_id.eq.$userId,friendships_addressee.requester_id.eq.$userId')
          .or('friendships_requester.status.eq.accepted,friendships_addressee.status.eq.accepted')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching friends activity feed: $error');
      rethrow;
    }
  }

  // Get activities for a specific entity
  Future<List<Activity>> getEntityActivities({
    required String entityType,
    required String entityId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('activities')
          .select()
          .eq('entity_type', entityType)
          .eq('entity_id', entityId)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Activity.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching entity activities: $error');
      rethrow;
    }
  }

  // Quick methods for common activity types
  Future<Activity> logTaskCompleted({
    required String taskId,
    required String taskTitle,
    required String todoListId,
    required String todoListName,
  }) async {
    return createActivity(
      activityType: 'task_completed',
      entityType: 'task',
      entityId: taskId,
      metadata: {
        'task_title': taskTitle,
        'todo_list_id': todoListId,
        'todo_list_name': todoListName,
      },
    );
  }

  Future<Activity> logTimerSessionCompleted({
    required String sessionId,
    required int sessionsCompleted,
    required int totalMinutes,
    String? taskId,
    String? todoListId,
  }) async {
    return createActivity(
      activityType: 'timer_session_completed',
      entityType: 'timer_session',
      entityId: sessionId,
      metadata: {
        'sessions_completed': sessionsCompleted,
        'total_minutes': totalMinutes,
        if (taskId != null) 'task_id': taskId,
        if (todoListId != null) 'todo_list_id': todoListId,
      },
    );
  }

  Future<Activity> logTodoListCreated({
    required String todoListId,
    required String todoListName,
  }) async {
    return createActivity(
      activityType: 'todo_list_created',
      entityType: 'todo_list',
      entityId: todoListId,
      metadata: {
        'todo_list_name': todoListName,
      },
    );
  }

  Future<Activity> logTodoListShared({
    required String todoListId,
    required String todoListName,
    required String sharedWithUserId,
    required String sharedWithUsername,
  }) async {
    return createActivity(
      activityType: 'todo_list_shared',
      entityType: 'todo_list',
      entityId: todoListId,
      metadata: {
        'todo_list_name': todoListName,
        'shared_with_user_id': sharedWithUserId,
        'shared_with_username': sharedWithUsername,
      },
    );
  }

  // Delete activity
  Future<void> deleteActivity(String id) async {
    try {
      await _supabase
          .from('activities')
          .delete()
          .eq('id', id);
    } catch (error) {
      print('❌ Error deleting activity: $error');
      rethrow;
    }
  }

  // Update activity visibility
  Future<Activity> updateActivityVisibility(String id, bool isPublic) async {
    try {
      final response = await _supabase
          .from('activities')
          .update({'is_public': isPublic})
          .eq('id', id)
          .select()
          .single();

      return Activity.fromJson(response);
    } catch (error) {
      print('❌ Error updating activity visibility: $error');
      rethrow;
    }
  }
}
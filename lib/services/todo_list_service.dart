import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo_list_model.dart';
import 'supabase_auth_service.dart';

class TodoListService {
  static final TodoListService _instance = TodoListService._internal();
  factory TodoListService() => _instance;
  TodoListService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Ensure user record exists in database using auth service
  Future<void> _ensureUserRecord() async {
    try {
      await _authService.ensureCurrentUserRecord();
    } catch (error) {
      print('⚠️ Error ensuring user record in TodoListService: $error');
      // Don't rethrow - we want the app to continue working
    }
  }

  // Get all todo lists for current user
  Future<List<TodoList>> getUserTodoLists() async {
    try {
      final response = await _supabase
          .from('todo_lists')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_archived', false)
          .order('position');

      return (response as List)
          .map((json) => TodoList.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching todo lists: $error');
      rethrow;
    }
  }

  // Create a new todo list
  Future<TodoList> createTodoList({
    required String name,
    String? description,
    String? color,
    bool isPublic = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Ensure user record exists before creating todo list
      await _ensureUserRecord();
      
      // Get current max position
      final positionResponse = await _supabase
          .from('todo_lists')
          .select('position')
          .eq('user_id', userId)
          .order('position', ascending: false)
          .limit(1);

      final maxPosition = positionResponse.isNotEmpty 
          ? (positionResponse.first['position'] as int?) ?? 0
          : 0;

      final response = await _supabase
          .from('todo_lists')
          .insert({
            'user_id': userId,
            'name': name,
            'description': description,
            'color': color,
            'is_public': isPublic,
            'position': maxPosition + 1,
          })
          .select()
          .single();

      return TodoList.fromJson(response);
    } catch (error) {
      print('❌ Error creating todo list: $error');
      rethrow;
    }
  }

  // Update todo list
  Future<TodoList> updateTodoList(String id, {
    String? name,
    String? description,
    String? color,
    bool? isPublic,
    bool? isArchived,
    int? position,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (color != null) updateData['color'] = color;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (isArchived != null) updateData['is_archived'] = isArchived;
      if (position != null) updateData['position'] = position;

      final response = await _supabase
          .from('todo_lists')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return TodoList.fromJson(response);
    } catch (error) {
      print('❌ Error updating todo list: $error');
      rethrow;
    }
  }

  // Delete todo list
  Future<void> deleteTodoList(String id) async {
    try {
      await _supabase
          .from('todo_lists')
          .delete()
          .eq('id', id);
    } catch (error) {
      print('❌ Error deleting todo list: $error');
      rethrow;
    }
  }

  // Get public todo lists from friends
  Future<List<TodoList>> getFriendsTodoLists() async {
    try {
      final response = await _supabase
          .from('todo_lists')
          .select('''
            *,
            users!inner(username, display_name, avatar_url)
          ''')
          .eq('is_public', true)
          .neq('user_id', _supabase.auth.currentUser!.id);

      return (response as List)
          .map((json) => TodoList.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching friends todo lists: $error');
      rethrow;
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  // Get all tasks for a todo list
  Future<List<Task>> getTasks(String todoListId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('todo_list_id', todoListId)
          .isFilter('deleted_at', null)
          .order('position');

      return (response as List)
          .map((json) => Task.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching tasks: $error');
      rethrow;
    }
  }

  // Create a new task
  Future<Task> createTask({
    required String todoListId,
    required String title,
    String? description,
    PriorityLevel priority = PriorityLevel.medium,
    DateTime? dueDate,
  }) async {
    try {
      // First, get all existing tasks to increment their positions
      final existingTasks = await _supabase
          .from('tasks')
          .select('id, position')
          .eq('todo_list_id', todoListId)
          .isFilter('deleted_at', null)
          .order('position');

      // Increment positions of existing tasks
      for (final taskData in existingTasks) {
        await _supabase
            .from('tasks')
            .update({'position': (taskData['position'] as int) + 1})
            .eq('id', taskData['id']);
      }

      // Insert new task at position 0 (top of list)
      final response = await _supabase
          .from('tasks')
          .insert({
            'todo_list_id': todoListId,
            'title': title,
            'description': description,
            'priority': priority.name,
            'due_date': dueDate?.toIso8601String(),
            'position': 0,
          })
          .select()
          .single();

      return Task.fromJson(response);
    } catch (error) {
      print('❌ Error creating task: $error');
      rethrow;
    }
  }

  // Update task
  Future<Task> updateTask(String id, {
    String? title,
    String? description,
    PriorityLevel? priority,
    bool? isCompleted,
    DateTime? dueDate,
    int? position,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (priority != null) updateData['priority'] = priority.name;
      if (isCompleted != null) {
        updateData['is_completed'] = isCompleted;
        if (isCompleted) {
          updateData['completed_at'] = DateTime.now().toIso8601String();
        } else {
          updateData['completed_at'] = null;
        }
      }
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (position != null) updateData['position'] = position;

      final response = await _supabase
          .from('tasks')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Task.fromJson(response);
    } catch (error) {
      print('❌ Error updating task: $error');
      rethrow;
    }
  }

  // Toggle task completion
  Future<Task> toggleTaskCompletion(String id) async {
    try {
      // First get current state
      final currentResponse = await _supabase
          .from('tasks')
          .select('is_completed')
          .eq('id', id)
          .single();

      final isCurrentlyCompleted = currentResponse['is_completed'] as bool;
      final newCompletedState = !isCurrentlyCompleted;

      final updateData = {
        'is_completed': newCompletedState,
        'completed_at': newCompletedState ? DateTime.now().toIso8601String() : null,
      };

      final response = await _supabase
          .from('tasks')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Task.fromJson(response);
    } catch (error) {
      print('❌ Error toggling task completion: $error');
      rethrow;
    }
  }

  // Soft delete task
  Future<void> deleteTask(String id) async {
    try {
      await _supabase
          .from('tasks')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (error) {
      print('❌ Error deleting task: $error');
      rethrow;
    }
  }

  // Get overdue tasks for user
  Future<List<Task>> getOverdueTasks() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('tasks')
          .select('''
            *,
            todo_lists!inner(user_id)
          ''')
          .eq('todo_lists.user_id', userId)
          .eq('is_completed', false)
          .isFilter('deleted_at', null)
          .lt('due_date', now)
          .order('due_date');

      return (response as List)
          .map((json) => Task.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching overdue tasks: $error');
      rethrow;
    }
  }

  // Get tasks due today
  Future<List<Task>> getTasksDueToday() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('tasks')
          .select('''
            *,
            todo_lists!inner(user_id)
          ''')
          .eq('todo_lists.user_id', userId)
          .eq('is_completed', false)
          .isFilter('deleted_at', null)
          .gte('due_date', startOfDay.toIso8601String())
          .lt('due_date', endOfDay.toIso8601String())
          .order('due_date');

      return (response as List)
          .map((json) => Task.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching tasks due today: $error');
      rethrow;
    }
  }

  // Reorder tasks by updating positions
  Future<void> reorderTasks(String todoListId, List<Task> reorderedTasks) async {
    try {
      // Update positions for all tasks
      final batch = <Map<String, dynamic>>[];
      
      for (int i = 0; i < reorderedTasks.length; i++) {
        final task = reorderedTasks[i];
        if (task.position != i) {
          batch.add({
            'id': task.id,
            'position': i,
          });
        }
      }

      // Execute batch update if there are changes
      if (batch.isNotEmpty) {
        for (final update in batch) {
          await _supabase
              .from('tasks')
              .update({'position': update['position']})
              .eq('id', update['id']);
        }
      }
    } catch (error) {
      print('❌ Error reordering tasks: $error');
      rethrow;
    }
  }
}
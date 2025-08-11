import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timer_template_model.dart';

class TimerTemplateService {
  static final TimerTemplateService _instance = TimerTemplateService._internal();
  factory TimerTemplateService() => _instance;
  TimerTemplateService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  // Get all timer templates for current user
  Future<List<TimerTemplate>> getUserTimerTemplates() async {
    try {
      final response = await _supabase
          .from('timer_templates')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('is_default', ascending: false)
          .order('name');

      return (response as List)
          .map((json) => TimerTemplate.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching timer templates: $error');
      rethrow;
    }
  }

  // Get default timer template for user
  Future<TimerTemplate?> getDefaultTimerTemplate() async {
    try {
      final response = await _supabase
          .from('timer_templates')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_default', true)
          .maybeSingle();

      return response != null ? TimerTemplate.fromJson(response) : null;
    } catch (error) {
      print('❌ Error fetching default timer template: $error');
      rethrow;
    }
  }

  // Create default template if none exists
  Future<TimerTemplate> ensureDefaultTemplate() async {
    try {
      final existing = await getDefaultTimerTemplate();
      if (existing != null) return existing;

      // Create default Pomodoro template
      return createTimerTemplate(
        name: 'Default Pomodoro',
        description: 'Classic 25-minute work sessions with 5-minute breaks',
        workDurationMinutes: 25,
        breakDurationMinutes: 5,
        longBreakDurationMinutes: 15,
        longBreakInterval: 4,
        totalSessions: 4,
        isDefault: true,
        color: '#FF6B6B',
      );
    } catch (error) {
      print('❌ Error ensuring default template: $error');
      rethrow;
    }
  }

  // Create a new timer template
  Future<TimerTemplate> createTimerTemplate({
    required String name,
    String? description,
    required int workDurationMinutes,
    required int breakDurationMinutes,
    int? longBreakDurationMinutes,
    int? longBreakInterval,
    required int totalSessions,
    bool isDefault = false,
    String? color,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // If this is being set as default, unset other defaults
      if (isDefault) {
        await _supabase
            .from('timer_templates')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true);
      }

      final response = await _supabase
          .from('timer_templates')
          .insert({
            'user_id': userId,
            'name': name,
            'description': description,
            'work_duration_minutes': workDurationMinutes,
            'break_duration_minutes': breakDurationMinutes,
            'long_break_duration_minutes': longBreakDurationMinutes,
            'long_break_interval': longBreakInterval,
            'total_sessions': totalSessions,
            'is_default': isDefault,
            'color': color,
          })
          .select()
          .single();

      return TimerTemplate.fromJson(response);
    } catch (error) {
      print('❌ Error creating timer template: $error');
      rethrow;
    }
  }

  // Update timer template
  Future<TimerTemplate> updateTimerTemplate(String id, {
    String? name,
    String? description,
    int? workDurationMinutes,
    int? breakDurationMinutes,
    int? longBreakDurationMinutes,
    int? longBreakInterval,
    int? totalSessions,
    bool? isDefault,
    String? color,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (workDurationMinutes != null) updateData['work_duration_minutes'] = workDurationMinutes;
      if (breakDurationMinutes != null) updateData['break_duration_minutes'] = breakDurationMinutes;
      if (longBreakDurationMinutes != null) updateData['long_break_duration_minutes'] = longBreakDurationMinutes;
      if (longBreakInterval != null) updateData['long_break_interval'] = longBreakInterval;
      if (totalSessions != null) updateData['total_sessions'] = totalSessions;
      if (isDefault != null) updateData['is_default'] = isDefault;
      if (color != null) updateData['color'] = color;

      // If this is being set as default, unset other defaults
      if (isDefault == true) {
        await _supabase
            .from('timer_templates')
            .update({'is_default': false})
            .eq('user_id', _supabase.auth.currentUser!.id)
            .eq('is_default', true)
            .neq('id', id);
      }

      final response = await _supabase
          .from('timer_templates')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return TimerTemplate.fromJson(response);
    } catch (error) {
      print('❌ Error updating timer template: $error');
      rethrow;
    }
  }

  // Delete timer template
  Future<void> deleteTimerTemplate(String id) async {
    try {
      await _supabase
          .from('timer_templates')
          .delete()
          .eq('id', id);
    } catch (error) {
      print('❌ Error deleting timer template: $error');
      rethrow;
    }
  }

  // Get timer template by ID
  Future<TimerTemplate?> getTimerTemplate(String id) async {
    try {
      final response = await _supabase
          .from('timer_templates')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? TimerTemplate.fromJson(response) : null;
    } catch (error) {
      print('❌ Error fetching timer template: $error');
      rethrow;
    }
  }
}
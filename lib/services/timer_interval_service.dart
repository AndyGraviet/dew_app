import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timer_interval_model.dart';
import '../models/timer_session_model.dart';

class TimerIntervalService {
  static final TimerIntervalService _instance = TimerIntervalService._internal();
  factory TimerIntervalService() => _instance;
  TimerIntervalService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all intervals for a timer session
  Future<List<TimerInterval>> getSessionIntervals(String timerSessionId) async {
    try {
      final response = await _supabase
          .from('timer_intervals')
          .select()
          .eq('timer_session_id', timerSessionId)
          .order('interval_number');

      return (response as List)
          .map((json) => TimerInterval.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching timer intervals: $error');
      rethrow;
    }
  }

  // Create a new timer interval
  Future<TimerInterval> createTimerInterval({
    required String timerSessionId,
    required int intervalNumber,
    required IntervalType intervalType,
    required int plannedDurationMinutes,
  }) async {
    try {
      final response = await _supabase
          .from('timer_intervals')
          .insert({
            'timer_session_id': timerSessionId,
            'interval_number': intervalNumber,
            'interval_type': intervalType.value,
            'planned_duration_minutes': plannedDurationMinutes,
          })
          .select()
          .single();

      return TimerInterval.fromJson(response);
    } catch (error) {
      print('❌ Error creating timer interval: $error');
      rethrow;
    }
  }

  // Start timer interval
  Future<TimerInterval> startTimerInterval(String intervalId) async {
    try {
      final response = await _supabase
          .from('timer_intervals')
          .update({
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', intervalId)
          .select()
          .single();

      return TimerInterval.fromJson(response);
    } catch (error) {
      print('❌ Error starting timer interval: $error');
      rethrow;
    }
  }

  // Complete timer interval
  Future<TimerInterval> completeTimerInterval(
    String intervalId, {
    required int actualDurationSeconds,
    int? productivityRating,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('timer_intervals')
          .update({
            'completed_at': DateTime.now().toIso8601String(),
            'actual_duration_seconds': actualDurationSeconds,
            'was_completed': true,
            'productivity_rating': productivityRating,
            'notes': notes,
          })
          .eq('id', intervalId)
          .select()
          .single();

      return TimerInterval.fromJson(response);
    } catch (error) {
      print('❌ Error completing timer interval: $error');
      rethrow;
    }
  }

  // Skip timer interval
  Future<TimerInterval> skipTimerInterval(String intervalId, {String? notes}) async {
    try {
      final response = await _supabase
          .from('timer_intervals')
          .update({
            'was_skipped': true,
            'notes': notes,
          })
          .eq('id', intervalId)
          .select()
          .single();

      return TimerInterval.fromJson(response);
    } catch (error) {
      print('❌ Error skipping timer interval: $error');
      rethrow;
    }
  }

  // Update interval productivity rating and notes
  Future<TimerInterval> updateIntervalFeedback(
    String intervalId, {
    int? productivityRating,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (productivityRating != null) updateData['productivity_rating'] = productivityRating;
      if (notes != null) updateData['notes'] = notes;

      final response = await _supabase
          .from('timer_intervals')
          .update(updateData)
          .eq('id', intervalId)
          .select()
          .single();

      return TimerInterval.fromJson(response);
    } catch (error) {
      print('❌ Error updating interval feedback: $error');
      rethrow;
    }
  }

  // Get interval by ID
  Future<TimerInterval?> getTimerInterval(String id) async {
    try {
      final response = await _supabase
          .from('timer_intervals')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? TimerInterval.fromJson(response) : null;
    } catch (error) {
      print('❌ Error fetching timer interval: $error');
      rethrow;
    }
  }

  // Get productivity stats for user
  Future<Map<String, dynamic>> getUserProductivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Default to last 30 days if no dates provided
      endDate ??= DateTime.now();
      startDate ??= endDate.subtract(const Duration(days: 30));

      final response = await _supabase
          .from('timer_intervals')
          .select('''
            actual_duration_seconds,
            productivity_rating,
            was_completed,
            was_skipped,
            interval_type,
            timer_sessions!inner(user_id)
          ''')
          .eq('timer_sessions.user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final intervals = response as List;
      
      int totalIntervals = intervals.length;
      int completedIntervals = intervals.where((i) => i['was_completed'] == true).length;
      int skippedIntervals = intervals.where((i) => i['was_skipped'] == true).length;
      
      // Calculate total focus time (work intervals only)
      int totalFocusTimeSeconds = intervals
          .where((i) => i['interval_type'] == 'work' && i['actual_duration_seconds'] != null)
          .fold(0, (sum, i) => sum + (i['actual_duration_seconds'] as int));

      // Calculate average productivity rating
      final ratingsOnly = intervals
          .where((i) => i['productivity_rating'] != null)
          .map((i) => i['productivity_rating'] as int)
          .toList();
      
      double averageProductivity = ratingsOnly.isNotEmpty
          ? ratingsOnly.reduce((a, b) => a + b) / ratingsOnly.length
          : 0.0;

      return {
        'total_intervals': totalIntervals,
        'completed_intervals': completedIntervals,
        'skipped_intervals': skippedIntervals,
        'completion_rate': totalIntervals > 0 ? completedIntervals / totalIntervals : 0.0,
        'total_focus_time_minutes': (totalFocusTimeSeconds / 60).round(),
        'average_productivity_rating': averageProductivity,
        'total_rated_intervals': ratingsOnly.length,
      };
    } catch (error) {
      print('❌ Error fetching productivity stats: $error');
      rethrow;
    }
  }
}
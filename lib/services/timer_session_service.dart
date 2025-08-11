import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timer_session_model.dart';
import '../models/timer_interval_model.dart';
import '../models/timer_template_model.dart';

class TimerSessionService {
  static final TimerSessionService _instance = TimerSessionService._internal();
  factory TimerSessionService() => _instance;
  TimerSessionService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current active timer session
  Future<TimerSession?> getCurrentActiveSession() async {
    try {
      final response = await _supabase
          .from('timer_sessions')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .in_('status', ['running', 'paused'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? TimerSession.fromJson(response) : null;
    } catch (error) {
      print('❌ Error fetching current active session: $error');
      rethrow;
    }
  }

  // Get timer sessions for user
  Future<List<TimerSession>> getUserTimerSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('timer_sessions')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => TimerSession.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching timer sessions: $error');
      rethrow;
    }
  }

  // Create a new timer session from template
  Future<TimerSession> createTimerSession({
    TimerTemplate? template,
    String? taskId,
    String? todoListId,
    String? sessionName,
    int? workDurationMinutes,
    int? breakDurationMinutes,
    int? longBreakDurationMinutes,
    int? longBreakInterval,
    int? totalSessions,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Use template values if provided, otherwise use parameters or defaults
      final workDuration = workDurationMinutes ?? template?.workDurationMinutes ?? 25;
      final breakDuration = breakDurationMinutes ?? template?.breakDurationMinutes ?? 5;
      final longBreakDuration = longBreakDurationMinutes ?? template?.longBreakDurationMinutes ?? 15;
      final longBreakInt = longBreakInterval ?? template?.longBreakInterval ?? 4;
      final totalSess = totalSessions ?? template?.totalSessions ?? 4;

      final response = await _supabase
          .from('timer_sessions')
          .insert({
            'user_id': userId,
            'timer_template_id': template?.id,
            'task_id': taskId,
            'todo_list_id': todoListId,
            'session_name': sessionName ?? template?.name,
            'work_duration_minutes': workDuration,
            'break_duration_minutes': breakDuration,
            'long_break_duration_minutes': longBreakDuration,
            'long_break_interval': longBreakInt,
            'total_sessions': totalSess,
            'current_session': 1,
            'status': TimerSessionStatus.notStarted.value,
            'current_interval_type': IntervalType.work.value,
          })
          .select()
          .single();

      return TimerSession.fromJson(response);
    } catch (error) {
      print('❌ Error creating timer session: $error');
      rethrow;
    }
  }

  // Start timer session
  Future<TimerSession> startTimerSession(String sessionId) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('timer_sessions')
          .update({
            'status': TimerSessionStatus.running.value,
            'started_at': now.toIso8601String(),
            'current_interval_started_at': now.toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return TimerSession.fromJson(response);
    } catch (error) {
      print('❌ Error starting timer session: $error');
      rethrow;
    }
  }

  // Pause timer session
  Future<TimerSession> pauseTimerSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('timer_sessions')
          .update({
            'status': TimerSessionStatus.paused.value,
            'paused_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return TimerSession.fromJson(response);
    } catch (error) {
      print('❌ Error pausing timer session: $error');
      rethrow;
    }
  }

  // Resume timer session
  Future<TimerSession> resumeTimerSession(String sessionId, int pauseDurationSeconds) async {
    try {
      final response = await _supabase
          .from('timer_sessions')
          .update({
            'status': TimerSessionStatus.running.value,
            'paused_at': null,
            'total_pause_duration': pauseDurationSeconds,
            'current_interval_started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return TimerSession.fromJson(response);
    } catch (error) {
      print('❌ Error resuming timer session: $error');
      rethrow;
    }
  }

  // Complete current interval and move to next
  Future<TimerSession> completeCurrentInterval(String sessionId) async {
    try {
      // Get current session
      final currentSession = await getTimerSession(sessionId);
      if (currentSession == null) {
        throw Exception('Timer session not found');
      }

      IntervalType nextIntervalType;
      int nextSession = currentSession.currentSession;

      // Determine next interval type
      if (currentSession.currentIntervalType == IntervalType.work) {
        // After work, check if it's time for long break
        final shouldBeLongBreak = currentSession.longBreakInterval != null &&
            currentSession.currentSession % currentSession.longBreakInterval! == 0;
        
        nextIntervalType = shouldBeLongBreak ? IntervalType.longBreak : IntervalType.break_;
      } else {
        // After break, move to next work session
        nextIntervalType = IntervalType.work;
        nextSession = currentSession.currentSession + 1;
      }

      // Check if session is complete
      final isSessionComplete = nextSession > currentSession.totalSessions;
      
      final updateData = <String, dynamic>{
        'current_interval_type': nextIntervalType.value,
        'current_session': nextSession,
        'current_interval_started_at': DateTime.now().toIso8601String(),
      };

      if (isSessionComplete) {
        updateData['status'] = TimerSessionStatus.completed.value;
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('timer_sessions')
          .update(updateData)
          .eq('id', sessionId)
          .select()
          .single();

      return TimerSession.fromJson(response);
    } catch (error) {
      print('❌ Error completing current interval: $error');
      rethrow;
    }
  }

  // Cancel timer session
  Future<TimerSession> cancelTimerSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('timer_sessions')
          .update({
            'status': TimerSessionStatus.cancelled.value,
          })
          .eq('id', sessionId)
          .select()
          .single();

      return TimerSession.fromJson(response);
    } catch (error) {
      print('❌ Error cancelling timer session: $error');
      rethrow;
    }
  }

  // Get timer session by ID
  Future<TimerSession?> getTimerSession(String id) async {
    try {
      final response = await _supabase
          .from('timer_sessions')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? TimerSession.fromJson(response) : null;
    } catch (error) {
      print('❌ Error fetching timer session: $error');
      rethrow;
    }
  }

  // Get completed sessions count for today
  Future<int> getTodayCompletedSessionsCount() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('timer_sessions')
          .select('id', count: CountOption.exact)
          .eq('user_id', userId)
          .eq('status', TimerSessionStatus.completed.value)
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String());

      return response.count ?? 0;
    } catch (error) {
      print('❌ Error fetching today\'s completed sessions count: $error');
      rethrow;
    }
  }

  // Get total focus time for today
  Future<int> getTodayFocusTimeMinutes() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('timer_sessions')
          .select('work_duration_minutes, current_session')
          .eq('user_id', userId)
          .eq('status', TimerSessionStatus.completed.value)
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String());

      int totalMinutes = 0;
      for (final session in response as List) {
        final workDuration = session['work_duration_minutes'] as int;
        final completedSessions = session['current_session'] as int;
        totalMinutes += workDuration * completedSessions;
      }

      return totalMinutes;
    } catch (error) {
      print('❌ Error fetching today\'s focus time: $error');
      rethrow;
    }
  }
}
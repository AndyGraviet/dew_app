import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';

class FriendshipService {
  static final FriendshipService _instance = FriendshipService._internal();
  factory FriendshipService() => _instance;
  FriendshipService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Send friend request
  Future<Friendship> sendFriendRequest(String addresseeId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Check if friendship already exists
      final existing = await _supabase
          .from('friendships')
          .select()
          .or('and(requester_id.eq.$userId,addressee_id.eq.$addresseeId),and(requester_id.eq.$addresseeId,addressee_id.eq.$userId)')
          .maybeSingle();

      if (existing != null) {
        throw Exception('Friendship already exists');
      }

      final response = await _supabase
          .from('friendships')
          .insert({
            'requester_id': userId,
            'addressee_id': addresseeId,
            'status': FriendshipStatus.pending.name,
          })
          .select()
          .single();

      return Friendship.fromJson(response);
    } catch (error) {
      print('❌ Error sending friend request: $error');
      rethrow;
    }
  }

  // Accept friend request
  Future<Friendship> acceptFriendRequest(String friendshipId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .update({
            'status': FriendshipStatus.accepted.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId)
          .select()
          .single();

      return Friendship.fromJson(response);
    } catch (error) {
      print('❌ Error accepting friend request: $error');
      rethrow;
    }
  }

  // Decline friend request
  Future<Friendship> declineFriendRequest(String friendshipId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .update({
            'status': FriendshipStatus.declined.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId)
          .select()
          .single();

      return Friendship.fromJson(response);
    } catch (error) {
      print('❌ Error declining friend request: $error');
      rethrow;
    }
  }

  // Block user
  Future<Friendship> blockUser(String friendshipId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .update({
            'status': FriendshipStatus.blocked.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId)
          .select()
          .single();

      return Friendship.fromJson(response);
    } catch (error) {
      print('❌ Error blocking user: $error');
      rethrow;
    }
  }

  // Remove friendship
  Future<void> removeFriendship(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId);
    } catch (error) {
      print('❌ Error removing friendship: $error');
      rethrow;
    }
  }

  // Get user's friends (accepted friendships)
  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('friendships')
          .select('''
            id,
            status,
            created_at,
            updated_at,
            requester:users!requester_id(id, username, display_name, avatar_url),
            addressee:users!addressee_id(id, username, display_name, avatar_url)
          ''')
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .eq('status', FriendshipStatus.accepted.name)
          .order('updated_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching friends: $error');
      rethrow;
    }
  }

  // Get pending friend requests (received)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('friendships')
          .select('''
            id,
            status,
            created_at,
            requester:users!requester_id(id, username, display_name, avatar_url)
          ''')
          .eq('addressee_id', userId)
          .eq('status', FriendshipStatus.pending.name)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching pending requests: $error');
      rethrow;
    }
  }

  // Get sent friend requests
  Future<List<Map<String, dynamic>>> getSentRequests() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('friendships')
          .select('''
            id,
            status,
            created_at,
            addressee:users!addressee_id(id, username, display_name, avatar_url)
          ''')
          .eq('requester_id', userId)
          .eq('status', FriendshipStatus.pending.name)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      print('❌ Error fetching sent requests: $error');
      rethrow;
    }
  }

  // Check friendship status between two users
  Future<Friendship?> getFriendshipStatus(String otherUserId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('friendships')
          .select()
          .or('and(requester_id.eq.$userId,addressee_id.eq.$otherUserId),and(requester_id.eq.$otherUserId,addressee_id.eq.$userId)')
          .maybeSingle();

      return response != null ? Friendship.fromJson(response) : null;
    } catch (error) {
      print('❌ Error checking friendship status: $error');
      rethrow;
    }
  }

  // Search for users to add as friends
  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('users')
          .select()
          .neq('id', userId)
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(limit);

      return (response as List)
          .map((json) => User.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error searching users: $error');
      rethrow;
    }
  }

  // Get mutual friends count
  Future<int> getMutualFriendsCount(String otherUserId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // This is a complex query that would need to be implemented with RPC
      // For now, return 0 and implement later with a database function
      return 0;
    } catch (error) {
      print('❌ Error getting mutual friends count: $error');
      rethrow;
    }
  }

  // Get all friendships for user (for admin/debugging)
  Future<List<Friendship>> getAllUserFriendships() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('friendships')
          .select()
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => Friendship.fromJson(json))
          .toList();
    } catch (error) {
      print('❌ Error fetching all friendships: $error');
      rethrow;
    }
  }
}
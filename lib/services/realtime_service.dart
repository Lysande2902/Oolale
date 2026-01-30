import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing Supabase Realtime connections
/// Handles message streaming, typing indicators, and read receipts
class RealtimeService {
  final SupabaseClient _supabase;
  RealtimeChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  StreamController<TypingEvent>? _typingController;

  RealtimeService(this._supabase);

  /// Subscribe to a conversation channel for real-time messages
  /// [userId] - Current user's ID
  /// [otherUserId] - Other participant's ID
  /// [onMessage] - Callback when new message arrives
  Future<void> subscribeToConversation(
    String userId,
    String otherUserId,
    Function(Map<String, dynamic>) onMessage,
  ) async {
    // Create unique channel name for this conversation
    final channelName = _getChannelName(userId, otherUserId);

    // Unsubscribe from previous channel if exists
    await unsubscribe();

    // Create message stream controller
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    _messageController!.stream.listen(onMessage);

    // Subscribe to messages table changes
    _channel = _supabase.channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'intercom',
          callback: (payload) {
            final newMessage = payload.newRecord;
            // Only process messages for this conversation
            if (newMessage['remitente_id'] == userId || 
                newMessage['destinatario_id'] == userId) {
              _messageController?.add(newMessage);
            }
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('✅ Subscribed to conversation: $channelName');
          } else if (error != null) {
            debugPrint('❌ Subscription error: $error');
          }
        });
  }

  /// Broadcast typing indicator to the recipient
  /// [conversationId] - Unique conversation identifier
  /// [isTyping] - Whether user is currently typing
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    if (_channel == null) return;

    try {
      await _channel!.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'conversation_id': conversationId,
          'is_typing': isTyping,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('❌ Error sending typing indicator: $e');
    }
  }

  /// Listen for typing indicators from other user
  /// [conversationId] - Unique conversation identifier
  /// Returns stream of typing events
  Stream<TypingEvent> listenTypingIndicators(String conversationId) {
    _typingController = StreamController<TypingEvent>.broadcast();

    _channel?.onBroadcast(
      event: 'typing',
      callback: (payload) {
        if (payload['conversation_id'] == conversationId) {
          _typingController?.add(TypingEvent(
            conversationId: payload['conversation_id'] as String,
            isTyping: payload['is_typing'] as bool,
            timestamp: DateTime.parse(payload['timestamp'] as String),
          ));
        }
      },
    );

    return _typingController!.stream;
  }

  /// Mark message as read
  /// [messageId] - ID of the message to mark as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase.from('intercom').update({
        'leido': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      debugPrint('❌ Error marking message as read: $e');
    }
  }

  /// Mark all messages in a conversation as read
  /// [userId] - Current user's ID
  /// [otherUserId] - Other participant's ID
  Future<void> markAllMessagesAsRead(String userId, String otherUserId) async {
    try {
      await _supabase
          .from('intercom')
          .update({
            'leido': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('destinatario_id', userId)
          .eq('remitente_id', otherUserId)
          .eq('leido', false);
    } catch (e) {
      debugPrint('❌ Error marking all messages as read: $e');
    }
  }

  /// Unsubscribe from current channel and clean up resources
  Future<void> unsubscribe() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
    }

    await _messageController?.close();
    _messageController = null;

    await _typingController?.close();
    _typingController = null;
  }

  /// Generate unique channel name for conversation
  String _getChannelName(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'conversation:${ids[0]}:${ids[1]}';
  }

  /// Dispose of all resources
  void dispose() {
    unsubscribe();
  }
}

/// Typing event data class
class TypingEvent {
  final String conversationId;
  final bool isTyping;
  final DateTime timestamp;

  TypingEvent({
    required this.conversationId,
    required this.isTyping,
    required this.timestamp,
  });
}

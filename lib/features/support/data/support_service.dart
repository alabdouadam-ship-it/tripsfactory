import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/core/utils/logger.dart';

final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService(Supabase.instance.client);
});

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final int unreadCount;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      subject: map['subject'] as String,
      status: map['status'] as String? ?? 'open',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderRole;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      senderId: map['sender_id'] as String,
      senderRole: map['sender_role'] as String? ?? 'user',
      content: map['content'] as String,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class SupportService {
  final SupabaseClient _client;

  SupportService(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Get all tickets for the current user
  Future<List<SupportTicket>> getMyTickets() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((e) => SupportTicket.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      StructuredLogger.error(
        'SupportService',
        'Failed to load user tickets',
        e,
        st,
      );
      if (e is TripsFactoryException) rethrow;
      throw TripsFactoryException(
        'Unable to load support tickets. Please try again.',
        e,
      );
    }
  }

  /// Create a new support ticket with an initial message
  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw TripsFactoryException.withKey('not_authenticated', 'Not authenticated.');
    }

    try {
      final ticketRes = await _client
          .from('support_tickets')
          .insert({'user_id': userId, 'subject': subject})
          .select()
          .single();

      final ticket = SupportTicket.fromMap(ticketRes);

      try {
        await _client.from('support_messages').insert({
          'ticket_id': ticket.id,
          'sender_id': userId,
          'sender_role': 'user',
          'content': message,
        });
      } catch (msgError) {
        // Clean up orphaned ticket if message insert fails
        try {
          await _client.from('support_tickets').delete().eq('id', ticket.id);
        } catch (_) {
          // Best-effort cleanup
        }
        rethrow;
      }

      StructuredLogger.info(
        'SupportService',
        'Created new ticket ${ticket.id}',
      );
      return ticket;
    } catch (e, st) {
      StructuredLogger.error(
        'SupportService',
        'Failed to create ticket',
        e,
        st,
      );
      if (e is TripsFactoryException) rethrow;
      throw TripsFactoryException(
        'Unable to create support ticket. Please try again.',
        e,
      );
    }
  }

  /// Get messages for a ticket
  Future<List<SupportMessage>> getMessages(String ticketId) async {
    try {
      final response = await _client
          .from('support_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((e) => SupportMessage.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      StructuredLogger.error(
        'SupportService',
        'Failed to get messages for ticket $ticketId',
        e,
        st,
      );
      if (e is TripsFactoryException) rethrow;
      throw TripsFactoryException('Unable to load messages. Please try again.', e);
    }
  }

  /// Send a message in an existing ticket
  Future<void> sendMessage({
    required String ticketId,
    required String content,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw TripsFactoryException.withKey('not_authenticated', 'Not authenticated.');
    }

    try {
      await _client.from('support_messages').insert({
        'ticket_id': ticketId,
        'sender_id': userId,
        'sender_role': 'user',
        'content': content,
      });

      // Best-effort compatibility for environments before the DB trigger that
      // touches updated_at from support_messages inserts.
      try {
        await _client
            .from('support_tickets')
            .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', ticketId);
      } catch (e) {
        StructuredLogger.warning(
          'SupportService',
          'Message sent, but failed to touch ticket updated_at for $ticketId',
        );
      }
      StructuredLogger.info(
        'SupportService',
        'Message sent on ticket $ticketId',
      );
    } catch (e, st) {
      StructuredLogger.error(
        'SupportService',
        'Failed to send message on ticket $ticketId',
        e,
        st,
      );
      if (e is TripsFactoryException) rethrow;
      throw TripsFactoryException('Unable to send message. Please try again.', e);
    }
  }

  /// Mark admin messages as read for a ticket
  Future<void> markMessagesAsRead(String ticketId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _client
          .from('support_messages')
          .update({'is_read': true})
          .eq('ticket_id', ticketId)
          .eq('is_read', false);
    } catch (e) {
      StructuredLogger.warning(
        'SupportService',
        'Failed to mark messages as read for ticket $ticketId',
      );
      if (e is TripsFactoryException) rethrow;
      // Non-critical; don't throw to avoid disrupting UI
    }
  }

  /// Subscribe to new messages in a ticket (realtime)
  RealtimeChannel subscribeToMessages(
    String ticketId,
    void Function(SupportMessage) onMessage,
  ) {
    return _client
        .channel('support_messages:$ticketId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ticket_id',
            value: ticketId,
          ),
          callback: (payload) {
            final msg = SupportMessage.fromMap(payload.newRecord);
            onMessage(msg);
          },
        )
        .subscribe();
  }

  /// Get count of unread admin replies across all tickets
  Future<int> getUnreadCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    try {
      final response = await _client
          .from('support_messages')
          .select('id, support_tickets!inner(user_id)')
          .eq('support_tickets.user_id', userId)
          .eq('sender_role', 'admin')
          .eq('is_read', false);

      return (response as List).length;
    } catch (e, st) {
      StructuredLogger.error(
        'SupportService',
        'Failed to load unread count',
        e,
        st,
      );
      if (e is TripsFactoryException) rethrow;
      throw TripsFactoryException('Unable to load unread count. Please try again.', e);
    }
  }
}

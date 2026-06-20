import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsfactory/features/chat/data/chat_model.dart';
import 'package:tripsfactory/features/chat/data/chat_message_paging.dart';
import 'package:tripsfactory/core/config/storage_buckets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';

/// Abstraction for tests to inject a fake without Supabase.
abstract class IChatService {
  /// Streams the most recent [limit] messages for [bookingId] (newest first).
  /// The window is capped so long threads don't subscribe to full history.
  Stream<List<ChatMessage>> getMessages(
    String bookingId, {
    int limit = kChatPageSize,
  });

  /// Fetches up to [limit] messages older than [before] for [bookingId]
  /// (newest first), used to page in history above the live window.
  Future<List<ChatMessage>> fetchOlderMessages(
    String bookingId, {
    required DateTime before,
    int limit = kChatPageSize,
  });

  Future<List<ChatMessage>> fetchMessages(String bookingId);
  Future<void> sendMessage(
    String bookingId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
  });
  Future<String> uploadAudio(File file);
  Future<String> uploadImage(File file);
  Future<void> markMessagesAsRead(String bookingId);
}

final chatServiceProvider = Provider<IChatService>((ref) => ChatService());

final unreadChatCountProvider = StreamProvider.family<int, String>((
  ref,
  bookingId,
) {
  return ref
      .watch(chatServiceProvider)
      .getMessages(bookingId)
      .map((msgs) => msgs.where((m) => !m.isMe && !m.isRead).length);
});

class ChatService implements IChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _logTag = 'ChatService';
  static const String _attachmentsBucket = StorageBuckets.chatAttachments;

  @override
  Stream<List<ChatMessage>> getMessages(
    String bookingId, {
    int limit = kChatPageSize,
  }) {
    StructuredLogger.info(
      _logTag,
      'Subscribing to messages for booking: $bookingId (window=$limit)',
    );
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) {
          final currentUserId = _supabase.auth.currentUser?.id;
          if (currentUserId == null) {
            StructuredLogger.warning(_logTag, 'getMessages: No user logged in');
            return <ChatMessage>[];
          }
          return data
              .map((e) => ChatMessage.fromJsonWithUser(e, currentUserId))
              .toList();
        })
        .handleError((error) {
          StructuredLogger.error(_logTag, 'Message stream error', error);
          throw TripsFactoryException.withKey(
            'chat_stream_error',
            error.toString(),
            error,
          );
        });
  }

  @override
  Future<List<ChatMessage>> fetchOlderMessages(
    String bookingId, {
    required DateTime before,
    int limit = kChatPageSize,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw TripsFactoryException.withKey('auth_required', 'User must be logged in');
      }
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('booking_id', bookingId)
          .lt('created_at', before.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => ChatMessage.fromJsonWithUser(e, currentUserId))
          .toList();
    } catch (e) {
      StructuredLogger.error(_logTag, 'fetchOlderMessages error', e);
      throw TripsFactoryException.withKey('fetch_messages_failed', e.toString(), e);
    }
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String bookingId) async {
    try {
      StructuredLogger.info(
        _logTag,
        'Fetching messages for booking: $bookingId',
      );
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false);

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw TripsFactoryException.withKey('auth_required', 'User must be logged in');
      }

      return (response as List)
          .map((e) => ChatMessage.fromJsonWithUser(e, currentUserId))
          .toList();
    } catch (e) {
      StructuredLogger.error(_logTag, 'fetchMessages error', e);
      throw TripsFactoryException.withKey('fetch_messages_failed', e.toString(), e);
    }
  }

  @override
  Future<void> sendMessage(
    String bookingId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw TripsFactoryException.withKey('auth_required', 'User must be logged in');
      }

      StructuredLogger.info(
        _logTag,
        'Sending message to booking: $bookingId, type: $type',
      );
      await _supabase.from('messages').insert({
        'booking_id': bookingId,
        'sender_id': userId,
        'content': content,
        'type': type,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      StructuredLogger.error(_logTag, 'sendMessage error', e);
      throw TripsFactoryException.withKey('send_message_failed', e.toString(), e);
    }
  }

  @override
  Future<String> uploadAudio(File file) async {
    return _uploadFile(file, 'audio');
  }

  @override
  Future<String> uploadImage(File file) async {
    return _uploadFile(file, 'image');
  }

  Future<String> _uploadFile(File file, String context) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw TripsFactoryException.withKey('auth_required', 'User must be logged in');
      }

      final fileExt = file.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      StructuredLogger.info(_logTag, 'Uploading $context file: $filePath');
      await _supabase.storage
          .from(_attachmentsBucket)
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage
          .from(_attachmentsBucket)
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      StructuredLogger.error(_logTag, 'File upload error ($context)', e);
      throw TripsFactoryException.withKey('upload_failed', e.toString(), e);
    }
  }

  @override
  Future<void> markMessagesAsRead(String bookingId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      StructuredLogger.info(
        _logTag,
        'Marking messages as read for booking: $bookingId',
      );
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('booking_id', bookingId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      StructuredLogger.error(_logTag, 'markMessagesAsRead error', e);
    }
  }
}

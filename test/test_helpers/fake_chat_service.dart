import 'dart:io';
import 'package:tripship/features/chat/data/chat_model.dart';
import 'package:tripship/features/chat/data/chat_message_paging.dart';
import 'package:tripship/features/chat/data/chat_service.dart';

/// Fake chat service for conversion tests: no network, empty streams.
class FakeChatService implements IChatService {
  @override
  Stream<List<ChatMessage>> getMessages(
    String bookingId, {
    int limit = kChatPageSize,
  }) => Stream.value([]);

  @override
  Future<List<ChatMessage>> fetchOlderMessages(
    String bookingId, {
    required DateTime before,
    int limit = kChatPageSize,
  }) async => [];

  @override
  Future<List<ChatMessage>> fetchMessages(String bookingId) async => [];

  @override
  Future<void> sendMessage(
    String bookingId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<String> uploadAudio(File file) async => '';

  @override
  Future<String> uploadImage(File file) async => '';

  @override
  Future<void> markMessagesAsRead(String bookingId) async {}
}

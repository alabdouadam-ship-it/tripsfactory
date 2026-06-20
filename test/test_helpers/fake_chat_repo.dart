import 'package:tripsfactory/features/chat/data/chat_model.dart';
import 'package:tripsfactory/features/chat/data/chat_message_paging.dart';
import 'fake_chat_service.dart';

/// Provides a chat service preloaded with fixture messages for trust_ux tests.
FakeChatService fakeChatServiceWithMessages(List<ChatMessage> messages) {
  return FakeChatServiceWithMessages(messages);
}

/// Fake that emits a fixed list of messages once.
class FakeChatServiceWithMessages extends FakeChatService {
  FakeChatServiceWithMessages(this._messages);

  final List<ChatMessage> _messages;

  @override
  Stream<List<ChatMessage>> getMessages(
    String bookingId, {
    int limit = kChatPageSize,
  }) => Stream.value(List<ChatMessage>.from(_messages));
}

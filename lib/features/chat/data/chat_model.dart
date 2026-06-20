import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const ChatMessage._();

  const factory ChatMessage({
    required String id,
    @JsonKey(name: 'booking_id') required String bookingId,
    @JsonKey(name: 'sender_id') required String senderId,
    required String content,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default('text') String type,
    @Default({}) Map<String, dynamic> metadata,
    @Default(false) bool isMe,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
  }) = _ChatMessage;

  /// True when this message belongs to a booking chat thread.
  bool get isBookingThread => bookingId.isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  static ChatMessage fromJsonWithUser(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['booking_id'] ??= '';

    final msg = ChatMessage.fromJson(normalized);
    return msg.copyWith(isMe: msg.senderId == currentUserId);
  }
}

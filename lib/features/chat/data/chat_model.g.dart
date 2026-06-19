// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  bookingId: json['booking_id'] as String,
  offerId: json['offer_id'] as String?,
  senderId: json['sender_id'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  type: json['type'] as String? ?? 'text',
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  isMe: json['isMe'] as bool? ?? false,
  isRead: json['is_read'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking_id': instance.bookingId,
      'offer_id': instance.offerId,
      'sender_id': instance.senderId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'type': instance.type,
      'metadata': instance.metadata,
      'isMe': instance.isMe,
      'is_read': instance.isRead,
    };

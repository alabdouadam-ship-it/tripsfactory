import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripsfactory/core/config/storage_buckets.dart';

/// Resolves chat-attachment references (stored as full URLs in
/// `messages.content`) to short-lived signed URLs for the PRIVATE
/// `chat-attachments` bucket. A chat participant passes the storage SELECT
/// policy (`chat_attach_select_participants`), so client-side signing works
/// for both the sender and the recipient.
class ChatAttachmentUrl {
  ChatAttachmentUrl._();

  static const _bucket = StorageBuckets.chatAttachments;
  // Long-lived so a signed URL does not expire mid-session; access is still
  // gated by the storage SELECT policy at sign time.
  static const _ttlSeconds = 60 * 60 * 24 * 7; // 7 days
  static final Map<String, Future<String?>> _cache = {};

  /// The storage path within chat-attachments, or null if [stored] is not a
  /// chat-attachments reference (e.g. a local file path during optimistic send).
  static String? pathOf(String stored) {
    const marker = '/$_bucket/';
    if (!stored.startsWith('http')) return null;
    final i = stored.indexOf(marker);
    if (i == -1) return null;
    var p = stored.substring(i + marker.length);
    final q = p.indexOf('?');
    if (q != -1) p = p.substring(0, q);
    return Uri.decodeComponent(p);
  }

  /// Signed URL for [stored], cached by path. Returns [stored] unchanged when
  /// it is not a chat-attachments reference; null when signing fails.
  static Future<String?> resolve(String stored) {
    final path = pathOf(stored);
    if (path == null) return Future.value(stored);
    return _cache.putIfAbsent(path, () async {
      try {
        return await Supabase.instance.client.storage
            .from(_bucket)
            .createSignedUrl(path, _ttlSeconds);
      } catch (_) {
        _cache.remove(path); // allow a retry on the next render
        return null;
      }
    });
  }
}

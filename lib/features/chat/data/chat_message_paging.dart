import 'package:tripship/features/chat/data/chat_model.dart';

/// Number of messages fetched per page and kept in the live realtime window.
///
/// The realtime subscription is capped to this many of the most recent
/// messages so a long-lived thread never streams its entire history. Older
/// messages are paged in on demand via `fetchOlderMessages` /
/// `fetchOlderOfferMessages`.
const int kChatPageSize = 100;

/// Merges [incoming] messages into [current], keyed by message id, and returns
/// a new list sorted newest-first (descending `createdAt`).
///
/// [incoming] wins on id conflicts, so a realtime re-emission (e.g. an
/// `is_read` flip or edited content) replaces the stale copy in place.
///
/// This makes the message list robust to the capped realtime window: when the
/// live window shifts and an older message drops out of a stream emission, the
/// already-known copy is retained rather than vanishing. Combined with id-keyed
/// dedup, paging older history in never produces gaps or duplicates.
List<ChatMessage> upsertMessagesDesc(
  List<ChatMessage> current,
  Iterable<ChatMessage> incoming,
) {
  final byId = <String, ChatMessage>{};
  for (final m in current) {
    byId[m.id] = m;
  }
  for (final m in incoming) {
    byId[m.id] = m;
  }
  final merged = byId.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
}

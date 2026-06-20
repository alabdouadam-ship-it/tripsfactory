import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/features/chat/data/chat_message_paging.dart';
import 'package:tripsfactory/features/chat/data/chat_model.dart';

ChatMessage _msg(
  String id, {
  required int minute,
  bool isMe = false,
  bool isRead = false,
  String content = 'hello',
}) {
  return ChatMessage(
    id: id,
    bookingId: 'b1',
    senderId: isMe ? 'me' : 'other',
    content: content,
    createdAt: DateTime.utc(2026, 6, 17, 10, minute),
    isMe: isMe,
    isRead: isRead,
  );
}

void main() {
  group('upsertMessagesDesc', () {
    test('returns newest-first ordering regardless of input order', () {
      final result = upsertMessagesDesc(
        [],
        [
          _msg('a', minute: 1),
          _msg('c', minute: 3),
          _msg('b', minute: 2),
        ],
      );
      expect(result.map((m) => m.id), ['c', 'b', 'a']);
    });

    test('dedupes by id; incoming copy wins (e.g. is_read flip)', () {
      final current = [
        _msg('a', minute: 2, isRead: false),
        _msg('b', minute: 1),
      ];
      final result = upsertMessagesDesc(current, [
        _msg('a', minute: 2, isRead: true),
      ]);

      expect(result.length, 2, reason: 'no duplicate for id "a"');
      final a = result.firstWhere((m) => m.id == 'a');
      expect(a.isRead, isTrue, reason: 'incoming copy should win');
    });

    test('merging an older page never drops the live window (no gap)', () {
      // Live window holds the most recent messages.
      final liveWindow = [
        _msg('m100', minute: 50),
        _msg('m99', minute: 49),
        _msg('m98', minute: 48),
      ];
      // Older page fetched above the window.
      final olderPage = [
        _msg('m97', minute: 47),
        _msg('m96', minute: 46),
      ];

      final merged = upsertMessagesDesc(liveWindow, olderPage);

      expect(merged.map((m) => m.id), [
        'm100',
        'm99',
        'm98',
        'm97',
        'm96',
      ]);
    });

    test(
      'a message dropped from a shifting window is retained when re-emitted',
      () {
        // Accumulated set after first emission: window of 3.
        var acc = upsertMessagesDesc([], [
          _msg('m3', minute: 3),
          _msg('m2', minute: 2),
          _msg('m1', minute: 1),
        ]);

        // A new message arrives; the capped window now drops the oldest (m1),
        // so the stream re-emits only [m4, m3, m2]. m1 must NOT vanish.
        acc = upsertMessagesDesc(acc, [
          _msg('m4', minute: 4),
          _msg('m3', minute: 3),
          _msg('m2', minute: 2),
        ]);

        expect(acc.map((m) => m.id), ['m4', 'm3', 'm2', 'm1']);
      },
    );

    test('does not mutate the input list', () {
      final current = [_msg('a', minute: 1)];
      final result = upsertMessagesDesc(current, [_msg('b', minute: 2)]);
      expect(current.length, 1, reason: 'original list untouched');
      expect(result.length, 2);
    });

    test('kChatPageSize is a sane positive window', () {
      expect(kChatPageSize, greaterThan(0));
    });
  });
}

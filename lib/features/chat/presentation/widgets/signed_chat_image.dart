import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tripship/features/chat/data/chat_attachment_url.dart';

/// Renders a chat image attachment by resolving its stored reference to a
/// signed URL (private chat-attachments bucket). Uses the storage path as a
/// stable [CachedNetworkImage.cacheKey] so the on-device cache survives
/// signed-URL rotation.
class SignedChatImage extends StatelessWidget {
  const SignedChatImage({super.key, required this.stored});

  final String stored;

  Widget _loading() => const SizedBox(
        width: 120,
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

  Widget _broken() => const Icon(Icons.broken_image_outlined, size: 48);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ChatAttachmentUrl.resolve(stored),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _loading();
        final url = snap.data;
        if (url == null) return _broken();
        return CachedNetworkImage(
          imageUrl: url,
          cacheKey: ChatAttachmentUrl.pathOf(stored) ?? url,
          fit: BoxFit.cover,
          placeholder: (context, _) => _loading(),
          errorWidget: (context, _, _) => _broken(),
        );
      },
    );
  }
}

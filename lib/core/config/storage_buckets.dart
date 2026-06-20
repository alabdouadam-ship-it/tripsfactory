/// Supabase Storage bucket names, centralized in one place.
///
/// These are infrastructure identifiers, not user-facing brand copy: every
/// fork runs its own Supabase project but uses the same bucket names, so the
/// values are shared across forks. Centralizing them keeps the full set of
/// buckets discoverable and avoids stringly-typed literals scattered across
/// services.
///
/// Privacy (see project architecture):
/// - [userDocuments], [chatAttachments], [adminExports] are PRIVATE
///   (signed-URL access, RLS-gated).
/// - [avatars], [deliveryPhotos] are public-read.
class StorageBuckets {
  StorageBuckets._();

  /// KYC documents (identity/license/CR/vehicle). PRIVATE.
  static const String userDocuments = 'user_documents';

  /// User avatars. Public-read.
  static const String avatars = 'avatars';

  /// Chat audio/image attachments. PRIVATE (signed URLs, participant-gated).
  static const String chatAttachments = 'chat-attachments';

  /// Delivery handshake photos. Public-read.
  static const String deliveryPhotos = 'delivery_photos';

  /// Admin CSV exports. PRIVATE (24h signed URLs).
  static const String adminExports = 'admin_exports';
}

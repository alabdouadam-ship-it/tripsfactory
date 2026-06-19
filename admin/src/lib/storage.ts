import { supabase } from './supabase';

const USER_DOCUMENTS_BUCKET = 'user_documents';
const SIGNED_URL_TTL_SECONDS = 60 * 60; // 1 hour

export function isHttpUrl(value: string): boolean {
  return /^https?:\/\//i.test(value);
}

/**
 * Extract the storage path within the user_documents bucket from a stored
 * value — either a raw storage path, or a full public/signed Supabase URL.
 * Returns null for values that are not user_documents references (e.g. an
 * unrelated external URL).
 */
export function storagePathFromDocumentValue(value: string | null): string | null {
  if (!value) return null;
  if (isHttpUrl(value)) {
    try {
      const url = new URL(value);
      const publicMarker = `/storage/v1/object/public/${USER_DOCUMENTS_BUCKET}/`;
      const signedMarker = `/storage/v1/object/sign/${USER_DOCUMENTS_BUCKET}/`;
      const marker = url.pathname.includes(publicMarker)
        ? publicMarker
        : url.pathname.includes(signedMarker)
          ? signedMarker
          : null;
      if (!marker) return null;
      const i = url.pathname.indexOf(marker);
      return decodeURIComponent(url.pathname.slice(i + marker.length));
    } catch {
      return null;
    }
  }
  return value; // already a storage path
}

/**
 * Resolve a stored user_documents reference (path or legacy full URL) to a
 * short-lived signed URL. Works whether the bucket is public or private.
 * For non-user_documents values (external URLs) the value is returned as-is.
 * Returns null on failure or when there is no value.
 */
export async function signedUserDocUrl(value: string | null): Promise<string | null> {
  if (!value) return null;
  const path = storagePathFromDocumentValue(value);
  if (!path) return value; // external URL — pass through unchanged
  const { data, error } = await supabase.storage
    .from(USER_DOCUMENTS_BUCKET)
    .createSignedUrl(path, SIGNED_URL_TTL_SECONDS);
  if (error) return null;
  return data?.signedUrl ?? null;
}

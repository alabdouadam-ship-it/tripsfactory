const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/**
 * With `output: "export"`, dynamic routes are built as `placeholder.html` and
 * Hosting rewrites `/segment/:id` to that file. Hydration then leaves
 * `params.id` as `"placeholder"` while the browser URL still holds the real id.
 */
export function resolveExportedDynamicRouteId(
  paramId: string | string[] | undefined,
  pathname: string | null | undefined
): string | null {
  const raw = Array.isArray(paramId) ? paramId[0] : paramId;
  if (raw && raw !== "placeholder" && UUID_PATTERN.test(raw)) return raw;
  const last = pathname?.split("/").filter(Boolean).at(-1) ?? null;
  if (last && UUID_PATTERN.test(last)) return last;
  return null;
}

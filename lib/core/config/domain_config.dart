/// Canonical domain vocabulary — the string values that encode the app's
/// marketplace semantics (account types, verification statuses, traveler/
/// identity types, and booking roles).
///
/// These are the **persisted contract values** stored in / read from Supabase
/// (`profiles.account_type`, `traveler_status`, `company_status`,
/// `traveler_type`, `identity_type`, etc.). They must match the DB exactly, so
/// changing a value here is a backend-coordinated change, not a free rename.
///
/// Why centralize: a fork re-orienting the domain (logistics → ride-share →
/// services) re-labels these concepts. Keeping the canonical identifiers in one
/// place is the seam that makes that re-orientation tractable, and removes
/// stringly-typed magic values scattered across the codebase.
///
/// NOTE: This is increment 1 (data/domain layer). Presentation-layer call sites
/// still inline some of these literals and will be migrated incrementally.
class DomainConfig {
  DomainConfig._();

  // ── Account types (profiles.account_type) ──────────────────────────────────
  static const String accountIndividual = 'individual';
  static const String accountCompany = 'company';

  // ── Verification / approval statuses ────────────────────────────────────--
  // Used by both traveler_status and company_status.
  static const String statusNone = 'none';
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusSuspended = 'suspended';

  // ── Traveler types (profiles.traveler_type) ────────────────────────────────
  static const String travelerWithVehicle = 'with_vehicle';
  static const String travelerNoVehicle = 'no_vehicle';

  // ── Identity document types (profiles.identity_type) ───────────────────────
  static const String identityIdCard = 'id_card';
  static const String identityPassport = 'passport';
  static const String identityIqama = 'iqama';

  // ── Booking / marketplace roles ─────────────────────────────────────────--
  // Used for recipient-role tagging in notifications and chat.
  static const String roleSender = 'sender';
  static const String roleTraveler = 'traveler';
  static const String roleClient = 'client';
  static const String roleDriver = 'driver';
}

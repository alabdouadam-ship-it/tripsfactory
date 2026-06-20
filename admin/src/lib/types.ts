export type Profile = {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  phone_number: string | null;
  bio?: string | null;
  is_available?: boolean;
  // Traveler/Driver fields (stored directly on profiles, no separate table)
  traveler_status?: 'none' | 'pending' | 'approved' | 'rejected' | 'suspended' | 'blocked';
  traveler_type?: 'with_vehicle' | 'no_vehicle' | 'without_vehicle' | null;
  traveler_license_url?: string | null;
  identity_type?: string | null;
  identity_doc_url?: string | null;
  rental_contract_url?: string | null;
  is_driver?: boolean;
  subscription_expires_at?: string | null;
  license_expires_at?: string | null;
  driver_validity_date?: string | null;
  // Ratings
  traveler_rating_avg?: number;
  traveler_rating_count?: number;
  client_rating_avg?: number;
  client_rating_count?: number;
  // Admin/status
  is_suspended?: boolean;
  is_admin?: boolean;
  // Governance
  deleted_at?: string | null;
  is_frozen?: boolean;
  strike_count?: number;
  internal_notes?: string | null;
  identity_number?: string | null;
  identity_expiry?: string | null;
  is_verified_enterprise?: boolean;
  // Hard-block (cannot use the app) — independent of `is_suspended`
  is_blocked?: boolean;
  blocked_reason?: string | null;
  blocked_at?: string | null;
  blocked_by?: string | null;
  // Trust / featured badge system
  is_trusted?: boolean;
  is_featured?: boolean;
  trust_badge?:
    | 'trusted_driver'
    | 'featured_driver'
    | 'verified_partner'
    | string
    | null;
  trust_badge_set_at?: string | null;
  trust_badge_set_by?: string | null;
  // Email (read from auth.users via admin RPC; admin UI may receive it)
  email?: string | null;
  created_at: string;
  // Pending document uploads (for approval workflow)
  identity_doc_url_pending?: string | null;
  traveler_license_url_pending?: string | null;
  rental_contract_url_pending?: string | null;
  // Joined data
  vehicles?: Vehicle[];
};

// Driver is a Profile with traveler_status != 'none'
export type DriverProfile = Profile & {
  traveler_status: 'pending' | 'approved' | 'rejected' | 'suspended' | 'blocked';
};

export type Vehicle = {
  id: string;
  owner_id: string;
  make: string;
  model: string;
  year: number;
  plate_number: string;
  color?: string | null;
  vehicle_color?: string | null;
  vehicle_photo_url?: string | null;
  vehicle_photo_url_pending?: string | null;
  registration_doc_url?: string | null;
  registration_doc_url_pending?: string | null;
  vehicle_type?: string | null;
  created_at: string;
  updated_at?: string;
};

export type LocationLabel = {
  city_name_ar?: string | null;
  city_name_en?: string | null;
  latitude?: number | null;
  longitude?: number | null;
};

export type TripStatus = 'pending_approval' | 'available' | 'in_communication' | 'pending_confirmation' | 'booked' | 'full' | 'in_transit' | 'completed' | 'cancelled';

export type Trip = {
  id: string;
  traveler_id: string;
  origin_location_id: string;
  dest_location_id: string;
  max_weight_kg: number | null;
  suggested_price_per_kg: number | null;
  suggested_flat_price: number | null;
  departure_time: string;
  status: TripStatus;
  trip_type?: string;
  created_at: string;
  profile?: Profile;
  origin?: LocationLabel;
  dest?: LocationLabel;
  current_load_kg?: number;
  internal_notes?: string | null;
};

export type BookingStatus = 'pending' | 'accepted' | 'rejected' | 'in_transit' | 'delivered' | 'completed' | 'cancelled' | 'in_communication' | 'frozen' | 'disputed';

export type Booking = {
  id: string;
  trip_id?: string | null;
  traveler_id: string;
  requester_id?: string | null;
  price: number;
  status: BookingStatus;

  // Handshake Fields
  goods_handed_by_sender_at?: string;
  goods_received_by_traveler_at?: string;
  payment_marked_by_sender_at?: string;
  payment_confirmed_by_traveler_at?: string;
  goods_delivered_by_traveler_at?: string;
  goods_received_by_client_at?: string;

  timeline?: any[];
  created_at: string;

  // Joins
  trips?: Trip;
  driver_profile?: Profile;
  requester_profile?: Profile;

  // Operational Control Fields
  is_escalated?: boolean;
  refund_status?: string | null;
  internal_notes?: string | null;

  // Payment Governance Fields
  payment_disputed_at?: string | null;
  dispute_reason?: string | null;
  dispute_outcome?: 'favour_requester' | 'favour_traveler' | 'invalid_claim' | 'mutually_resolved' | null;
  dispute_resolved_at?: string | null;
  dispute_resolved_by?: string | null;
  evidence_urls?: string[] | null;
};

export type UserRestriction = {
  id: string;
  user_id: string;
  restriction_type: 'no_booking' | 'no_shipping' | 'read_only' | 'shadow_ban';
  reason: string;
  expires_at: string | null;
  admin_id: string;
  created_at: string;
};

// Note: the `reviews` table has been dropped; use `ratings` table instead.
// Rating type for admin review moderation.
export type Rating = {
  id: string;
  rater_id: string;
  rated_id: string;
  role_rated: string;
  rating: number;
  comment: string | null;
  comment_status: string | null;
  booking_id: string | null;
  created_at: string;
  rater?: Profile;
  rated?: Profile;
};

export type Message = {
  id: string;
  booking_id: string;
  sender_id: string;
  content?: string;
  type: 'text' | 'image' | 'voice' | 'audio';
  created_at: string;
  sender?: { full_name: string };
};

export type ReportTarget = 'user' | 'driver' | 'rating' | 'trip';

export type Report = {
  id: string;
  reporter_id: string;
  reported_id: string;
  reason: string;
  comment?: string;
  status: 'open' | 'pending' | 'investigating' | 'resolved' | 'dismissed';
  escalation_level: 'support' | 'ops' | 'legal';
  internal_notes?: string | null;
  admin_notes?: string | null;
  internal_comments: Array<{
    admin_id: string;
    admin_name: string;
    content: string;
    created_at: string;
  }>;
  resolution_action?: string;
  resolved_at?: string;
  resolved_by?: string;
  // First-class report targets
  target_type?: ReportTarget;
  target_rating_id?: string | null;
  target_trip_id?: string | null;
  created_at: string;
  reporter?: { full_name: string | null };
  reported?: { full_name: string | null };
};

// Alias for transition
export type UserReport = Report;

export type RiskScore = {
  user_id: string;
  risk_score: number;
  restriction_tier: 'none' | 'chat_only' | 'booking_lock' | 'full_suspension';
  last_recalculated_at: string;
  auto_restricted_at?: string;
};

export type RiskHistory = {
  id: string;
  user_id: string;
  old_score: number;
  new_score: number;
  reason: string;
  created_at: string;
};

export type AppSettings = {
  id: string;
  android_min_version: string;
  ios_min_version: string;
  force_update_message: string | null;
  global_message_active: boolean;
  global_message_content: string | null;
  support_whatsapp?: string | null;

  app_open: boolean;
  closed_message: string | null;
  closed_message_ar: string | null;

  terms_of_service: string | null;
  terms_of_service_ar: string | null;
  usage_policy: string | null;
  usage_policy_ar: string | null;

  marketing_main_text: string | null;
  marketing_main_text_ar: string | null;
  home_banner_text: string | null;
  home_banner_text_ar: string | null;

  first_launch_popup_active: boolean;
  first_launch_popup_title: string | null;
  first_launch_popup_title_ar: string | null;
  first_launch_popup_body: string | null;
  first_launch_popup_body_ar: string | null;
  first_launch_popup_image_url: string | null;
  first_launch_popup_action_url: string | null;
  first_launch_popup_target: 'all' | 'drivers' | 'individuals' | 'new_users';
  first_launch_popup_version: number;

  occasional_popup_active: boolean;
  occasional_popup_title: string | null;
  occasional_popup_title_ar: string | null;
  occasional_popup_body: string | null;
  occasional_popup_body_ar: string | null;
  occasional_popup_image_url: string | null;
  occasional_popup_action_url: string | null;
  occasional_popup_target: 'all' | 'drivers' | 'individuals' | 'new_users';
  occasional_popup_published_at: string | null;

  created_at: string;
  updated_at: string;
};

export type AuditLogV2 = {
  id: string;
  admin_id: string | null;
  action_type: 'INSERT' | 'UPDATE' | 'DELETE';
  entity_name: string;
  entity_id: string;
  data_before: any | null;
  data_after: any | null;
  ip_address: string | null;
  user_agent: string | null;
  device_fingerprint: string | null;
  checksum: string | null;
  created_at: string;
  admin?: { full_name: string | null };
};

export type AdminAuditLog = {
  id: string;
  admin_id: string | null;
  action: string;
  target_type: string | null;
  target_id: string | null;
  details: Record<string, any> | null;
  created_at: string;
  admin?: { full_name: string | null } | null;
};

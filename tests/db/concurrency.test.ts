// DEPRECATED: This file tested the old accept_booking_offer RPC which used
// shipment_id/booking_type on bookings and the 'other_accepted' status.
// All of those were removed in migration 00021_offer_booking_split.sql.
//
// The equivalent concurrency tests now live in offer-rpcs.test.ts
// (see "Concurrency > concurrent accept_offer on same shipment").
//
// This file is kept as a placeholder to avoid breaking test discovery.

import { describe, it } from 'vitest';

describe('(DEPRECATED) accept_booking_offer concurrency', () => {
  it.skip('superseded by offer-rpcs.test.ts', () => {});
});

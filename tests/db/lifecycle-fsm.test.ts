import { describe, it, expect, beforeAll } from 'vitest';
import {
  serviceRoleClient,
  setupTestUsers,
  requester,
  traveler,
  ensureLocation,
} from './setup.js';

const ALLOWED_TRANSITIONS: [string, string][] = [
  ['pending', 'accepted'],
  ['pending', 'rejected'],
  ['pending', 'cancelled'],
  ['accepted', 'in_transit'],
  ['in_transit', 'delivered'],
  ['delivered', 'completed'],
  ['pending', 'in_communication'],
  ['in_communication', 'accepted'],
  ['in_communication', 'rejected'],
  ['in_communication', 'cancelled'],
];

const FORBIDDEN_TRANSITIONS: [string, string][] = [
  ['in_transit', 'cancelled'],
  ['delivered', 'in_transit'],
  ['delivered', 'cancelled'],
  ['delivered', 'pending'],
  ['delivered', 'accepted'],
  ['completed', 'pending'],
  ['completed', 'cancelled'],
  ['completed', 'delivered'],
  ['accepted', 'rejected'],
];

async function createBooking(status: string) {
  const { data } = await serviceRoleClient
    .from('bookings')
    .insert({
      requester_id: requester.userId,
      traveler_id: traveler.userId,
      offer_price: 10,
      status,
      booking_type: 'shipment',
    })
    .select('id')
    .single();
  if (!data?.id) throw new Error('createBooking failed');
  return data.id;
}

describe('Stage 2: Booking lifecycle FSM', () => {
  beforeAll(async () => {
    await setupTestUsers();
  });

  describe('Allowed transitions', () => {
    for (const [from, to] of ALLOWED_TRANSITIONS) {
      it(`${from} -> ${to} succeeds`, async () => {
        const id = await createBooking(from);
        const { error } = await requester.client.from('bookings').update({ status: to }).eq('id', id).select().single();
        expect(error).toBeNull();
      });
    }
  });

  describe('Forbidden transitions', () => {
    for (const [from, to] of FORBIDDEN_TRANSITIONS) {
      it(`${from} -> ${to} fails with ILLEGAL_TRANSITION or constraint`, async () => {
        const id = await createBooking(from);
        const { error } = await requester.client.from('bookings').update({ status: to }).eq('id', id).select().single();
        expect(error).toBeTruthy();
        expect(String(error?.message)).toMatch(/ILLEGAL_TRANSITION|cannot revert|cannot cancel|immutable/i);
      });
    }
  });

  describe('Edge cases', () => {
    it('reject after accepted fails', async () => {
      const id = await createBooking('accepted');
      const { error } = await requester.client.from('bookings').update({ status: 'rejected' }).eq('id', id).select().single();
      expect(error).toBeTruthy();
    });

    it('cancel after in_transit fails', async () => {
      const id = await createBooking('in_transit');
      const { error } = await requester.client.from('bookings').update({ status: 'cancelled' }).eq('id', id).select().single();
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/ILLEGAL_TRANSITION|in-transit/i);
    });

    it('delivered without in_transit (direct pending->delivered) - if enforced by trigger, should fail', async () => {
      const id = await createBooking('pending');
      const { error } = await requester.client.from('bookings').update({ status: 'delivered' }).eq('id', id).select().single();
      if (error) expect(String(error.message)).toMatch(/ILLEGAL|transition|invalid/i);
    });

    it('completed is immutable', async () => {
      const id = await createBooking('completed');
      const { error } = await requester.client.from('bookings').update({ status: 'pending' }).eq('id', id).select().single();
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/ILLEGAL_TRANSITION|immutable/i);
    });
  });
});

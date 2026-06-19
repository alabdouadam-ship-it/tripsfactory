import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import {
  serviceRoleClient,
  setupTestUsers,
  requester,
  traveler,
  ensureLocation,
} from './setup.js';

let shipmentId: string;
let locId: string;

async function createShipment(): Promise<string> {
  const { data, error } = await serviceRoleClient
    .from('shipments')
    .insert({
      sender_id: requester.userId,
      pickup_location_id: locId,
      dropoff_location_id: locId,
      status: 'pending',
      description: 'offer rpc test shipment',
    })
    .select('id')
    .single();
  if (error) throw new Error(`createShipment: ${error.message}`);
  return data!.id;
}

async function sendOffer(driverId: string, shipId: string, price: number, message?: string) {
  return traveler.client.rpc('send_offer_with_message', {
    p_driver_id: driverId,
    p_shipment_id: shipId,
    p_price: price,
    p_message: message ?? null,
  });
}

describe('Offer RPCs — edge cases', () => {
  beforeAll(async () => {
    await setupTestUsers();
    locId = await ensureLocation();
  });

  beforeEach(async () => {
    shipmentId = await createShipment();
  });

  // ── send_offer_with_message ─────────────────────────────────────

  describe('send_offer_with_message', () => {
    it('creates offer with status=sent', async () => {
      const { data, error } = await sendOffer(traveler.userId, shipmentId, 100, 'Hello');
      expect(error).toBeNull();
      expect(data).toBeDefined();
      expect(data.status).toBe('sent');
      expect(data.price).toBe(100);
    });

    it('rejects negative price', async () => {
      const { error } = await sendOffer(traveler.userId, shipmentId, -5);
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/INVALID_PRICE/i);
    });

    it('rejects wrong driver_id (FORBIDDEN)', async () => {
      // requester tries to send offer pretending to be traveler
      const { error } = await requester.client.rpc('send_offer_with_message', {
        p_driver_id: traveler.userId,
        p_shipment_id: shipmentId,
        p_price: 50,
        p_message: null,
      });
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/FORBIDDEN/i);
    });

    it('rejects offer on non-existent shipment', async () => {
      const { error } = await sendOffer(
        traveler.userId,
        '00000000-0000-0000-0000-000000000000',
        50,
      );
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/SHIPMENT_NOT_FOUND/i);
    });

    it('blocks offer after shipment already has accepted offer', async () => {
      // First offer
      const { data: offer1 } = await sendOffer(traveler.userId, shipmentId, 100);
      expect(offer1?.id).toBeDefined();

      // Accept first offer
      const { error: acceptErr } = await requester.client.rpc('accept_offer', {
        p_offer_id: offer1!.id,
        p_shipment_owner_id: requester.userId,
      });
      expect(acceptErr).toBeNull();

      // Second offer should fail
      const { error } = await sendOffer(traveler.userId, shipmentId, 200);
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/SHIPMENT_ALREADY_ACCEPTED/i);
    });
  });

  // ── accept_offer ────────────────────────────────────────────────

  describe('accept_offer', () => {
    it('accepts a sent offer and rejects siblings', async () => {
      const { data: o1 } = await sendOffer(traveler.userId, shipmentId, 100);
      const { data: o2 } = await sendOffer(traveler.userId, shipmentId, 200);
      expect(o1?.id).toBeDefined();
      expect(o2?.id).toBeDefined();

      const { error } = await requester.client.rpc('accept_offer', {
        p_offer_id: o1!.id,
        p_shipment_owner_id: requester.userId,
      });
      expect(error).toBeNull();

      // Verify states
      const { data: offers } = await serviceRoleClient
        .from('offers')
        .select('id, status, rejection_reason')
        .in('id', [o1!.id, o2!.id]);

      const accepted = offers?.find((o) => o.id === o1!.id);
      const rejected = offers?.find((o) => o.id === o2!.id);
      expect(accepted?.status).toBe('accepted');
      expect(rejected?.status).toBe('rejected');
      expect(rejected?.rejection_reason).toBe('other_offer_accepted');
    });

    it('rejects double-accept on same shipment', async () => {
      const { data: o1 } = await sendOffer(traveler.userId, shipmentId, 100);
      const { data: o2 } = await sendOffer(traveler.userId, shipmentId, 200);

      // Accept first
      await requester.client.rpc('accept_offer', {
        p_offer_id: o1!.id,
        p_shipment_owner_id: requester.userId,
      });

      // Try to accept second (already auto-rejected)
      const { error } = await requester.client.rpc('accept_offer', {
        p_offer_id: o2!.id,
        p_shipment_owner_id: requester.userId,
      });
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/OFFER_NOT_SENT|SHIPMENT_ALREADY_ACCEPTED/i);
    });

    it('FORBIDDEN if caller is not shipment owner', async () => {
      const { data: offer } = await sendOffer(traveler.userId, shipmentId, 100);
      const { error } = await traveler.client.rpc('accept_offer', {
        p_offer_id: offer!.id,
        p_shipment_owner_id: traveler.userId,
      });
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/FORBIDDEN/i);
    });

    it('updates shipment status to accepted', async () => {
      const { data: offer } = await sendOffer(traveler.userId, shipmentId, 100);
      await requester.client.rpc('accept_offer', {
        p_offer_id: offer!.id,
        p_shipment_owner_id: requester.userId,
      });

      const { data: ship } = await serviceRoleClient
        .from('shipments')
        .select('status')
        .eq('id', shipmentId)
        .single();
      expect(ship?.status).toBe('accepted');
    });
  });

  // ── reject_offer ────────────────────────────────────────────────

  describe('reject_offer', () => {
    it('rejects a sent offer', async () => {
      const { data: offer } = await sendOffer(traveler.userId, shipmentId, 100);
      const { error } = await requester.client.rpc('reject_offer', {
        p_offer_id: offer!.id,
        p_shipment_owner_id: requester.userId,
      });
      expect(error).toBeNull();

      const { data } = await serviceRoleClient
        .from('offers')
        .select('status')
        .eq('id', offer!.id)
        .single();
      expect(data?.status).toBe('rejected');
    });

    it('cannot reject an already accepted offer', async () => {
      const { data: offer } = await sendOffer(traveler.userId, shipmentId, 100);
      await requester.client.rpc('accept_offer', {
        p_offer_id: offer!.id,
        p_shipment_owner_id: requester.userId,
      });

      const { error } = await requester.client.rpc('reject_offer', {
        p_offer_id: offer!.id,
        p_shipment_owner_id: requester.userId,
      });
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/INVALID_STATE/i);
    });

    it('cannot reject an already cancelled offer', async () => {
      const { data: offer } = await sendOffer(traveler.userId, shipmentId, 100);
      await traveler.client.rpc('cancel_offer', {
        p_offer_id: offer!.id,
        p_driver_id: traveler.userId,
      });

      const { error } = await requester.client.rpc('reject_offer', {
        p_offer_id: offer!.id,
        p_shipment_owner_id: requester.userId,
      });
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/INVALID_STATE/i);
    });
  });

  // ── cancel_offer ────────────────────────────────────────────────

  describe('cancel_offer', () => {
    it('driver cancels own sent offer', async () => {
      const { data: offer } = await sendOffer(traveler.userId, shipmentId, 100);
      const { error } = await traveler.client.rpc('cancel_offer', {
        p_offer_id: offer!.id,
        p_driver_id: traveler.userId,
      });
      expect(error).toBeNull();

      const { data } = await serviceRoleClient
        .from('offers')
        .select('status')
        .eq('id', offer!.id)
        .single();
      expect(data?.status).toBe('cancelled');
    });

    it('cannot cancel after acceptance', async () => {
      const { data: offer } = await sendOffer(traveler.userId, shipmentId, 100);
      await requester.client.rpc('accept_offer', {
        p_offer_id: offer!.id,
        p_shipment_owner_id: requester.userId,
      });

      const { error } = await traveler.client.rpc('cancel_offer', {
        p_offer_id: offer!.id,
        p_driver_id: traveler.userId,
      });
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/INVALID_STATE/i);
    });

    it('FORBIDDEN if non-owner tries to cancel', async () => {
      const { data: offer } = await sendOffer(traveler.userId, shipmentId, 100);
      const { error } = await requester.client.rpc('cancel_offer', {
        p_offer_id: offer!.id,
        p_driver_id: requester.userId,
      });
      expect(error).toBeTruthy();
      expect(String(error?.message)).toMatch(/FORBIDDEN/i);
    });
  });

  // ── Concurrent accept race condition ────────────────────────────

  describe('Concurrency', () => {
    it('concurrent accept_offer on same shipment: only one succeeds', async () => {
      const { data: o1 } = await sendOffer(traveler.userId, shipmentId, 100);
      const { data: o2 } = await sendOffer(traveler.userId, shipmentId, 200);

      const results = await Promise.all([
        requester.client.rpc('accept_offer', {
          p_offer_id: o1!.id,
          p_shipment_owner_id: requester.userId,
        }),
        requester.client.rpc('accept_offer', {
          p_offer_id: o2!.id,
          p_shipment_owner_id: requester.userId,
        }),
      ]);

      const ok = results.filter((r) => !r.error);
      const fail = results.filter((r) => r.error);
      expect(ok.length).toBe(1);
      expect(fail.length).toBe(1);
      expect(String(fail[0]?.error?.message)).toMatch(
        /SHIPMENT_ALREADY_ACCEPTED|OFFER_NOT_SENT/i,
      );

      // Verify exactly one accepted
      const { data: offers } = await serviceRoleClient
        .from('offers')
        .select('id, status')
        .in('id', [o1!.id, o2!.id]);
      const accepted = offers?.filter((o) => o.status === 'accepted');
      expect(accepted?.length).toBe(1);
    });
  });
});

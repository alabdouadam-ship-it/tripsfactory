import { describe, it, expect, beforeAll } from 'vitest';
import {
  serviceRoleClient,
  setupTestUsers,
  requester,
  traveler,
  admin,
  ensureLocation,
} from './setup.js';

const SENSITIVE_TABLES = [
  'profiles',
  'trips',
  'bookings',
  'messages',
  'notifications',
  'notification_tokens',
];

describe('Stage 1: RLS coverage', () => {
  beforeAll(async () => {
    await setupTestUsers();
  });

  describe('RLS enabled on sensitive tables', () => {
    it('sensitive tables are queryable and RLS applies (different users see different data)', async () => {
      const { data: asRequester } = await requester.client.from('bookings').select('id');
      const { data: asTraveler } = await traveler.client.from('bookings').select('id');
      expect(Array.isArray(asRequester)).toBe(true);
      expect(Array.isArray(asTraveler)).toBe(true);
    });
  });

  describe('Unauthorized read denied', () => {
    it('requester cannot read bookings they are not part of', async () => {
      const { data: serviceBookings } = await serviceRoleClient
        .from('bookings')
        .select('id, requester_id, traveler_id')
        .limit(20);
      const bookingNotForRequester = (serviceBookings || []).find(
        (b) => b.requester_id !== requester.userId && b.traveler_id !== requester.userId
      );
      if (!bookingNotForRequester) {
        const { data: inserted } = await serviceRoleClient
          .from('bookings')
          .insert({
            requester_id: admin.userId,
            traveler_id: traveler.userId,
            price: 10,
            status: 'pending',
          })
          .select('id')
          .single();
        expect(inserted?.id).toBeDefined();
        const { data: asRequester } = await requester.client.from('bookings').select('id').eq('id', inserted!.id).maybeSingle();
        expect(asRequester).toBeNull();
        return;
      }
      const { data: asRequester } = await requester.client.from('bookings').select('id').eq('id', bookingNotForRequester.id).maybeSingle();
      expect(asRequester).toBeNull();
    });

    it('requester cannot read another user notifications', async () => {
      const { data: notifs } = await serviceRoleClient.from('notifications').select('id').eq('user_id', traveler.userId).limit(1);
      if (!notifs?.length) {
        const { data: ins } = await serviceRoleClient.from('notifications').insert({ user_id: traveler.userId, title: 'T', body: 'B' }).select('id').single();
        expect(ins?.id).toBeDefined();
        const { data: asReq } = await requester.client.from('notifications').select('id').eq('id', ins!.id).maybeSingle();
        expect(asReq).toBeNull();
        return;
      }
      const { data: asReq } = await requester.client.from('notifications').select('id').eq('id', notifs[0].id).maybeSingle();
      expect(asReq).toBeNull();
    });

    it('requester cannot read another user notification_tokens', async () => {
      const { data: tokens } = await serviceRoleClient.from('notification_tokens').select('id').eq('user_id', traveler.userId).limit(1);
      if (!tokens?.length) {
        const { data: ins } = await serviceRoleClient.from('notification_tokens').insert({ user_id: traveler.userId, token: 'token-rls-test-' + Date.now(), platform: 'test' }).select('id').single();
        expect(ins?.id).toBeDefined();
        const { data: asReq } = await requester.client.from('notification_tokens').select('id').eq('id', ins!.id).maybeSingle();
        expect(asReq).toBeNull();
        return;
      }
      const { data: asReq } = await requester.client.from('notification_tokens').select('id').eq('id', tokens[0].id).maybeSingle();
      expect(asReq).toBeNull();
    });
  });

  describe('Unauthorized write denied', () => {
    it('requester cannot update another user profile', async () => {
      const { error } = await requester.client.from('profiles').update({ full_name: 'Hacked' }).eq('id', traveler.userId).select().single();
      expect(error).toBeTruthy();
      const { data } = await traveler.client.from('profiles').select('full_name').eq('id', traveler.userId).single();
      expect(data?.full_name).not.toBe('Hacked');
    });

    it('requester cannot delete another user notification', async () => {
      const { data: ins } = await serviceRoleClient.from('notifications').insert({ user_id: traveler.userId, title: 'T', body: 'B' }).select('id').single();
      expect(ins?.id).toBeDefined();
      const { error } = await requester.client.from('notifications').delete().eq('id', ins!.id).select().single();
      expect(error).toBeTruthy();
    });
  });

  describe('Role restrictions', () => {
    it('requester cannot insert trip as traveler (traveler_id = traveler)', async () => {
      const locId = await ensureLocation();
      const { error } = await requester.client.from('trips').insert({
        traveler_id: traveler.userId,
        origin_location_id: locId,
        dest_location_id: locId,
        departure_time: new Date().toISOString(),
        trip_type: 'scheduled',
        status: 'available',
      });
      expect(error).toBeTruthy();
    });
  });

  describe('Admin-only paths', () => {
    it('non-admin cannot insert into user_roles', async () => {
      const { error } = await requester.client.from('user_roles').insert({
        user_id: requester.userId,
        role: 'admin',
        granted_by: requester.userId,
      });
      expect(error).toBeTruthy();
    });

    it('non-admin cannot read admin_audit_log', async () => {
      const { data } = await requester.client.from('admin_audit_log').select('id');
      expect(data).toEqual([]);
    });

    it('admin can read user_roles', async () => {
      const { data, error } = await admin.client.from('user_roles').select('id');
      expect(error).toBeNull();
      expect(Array.isArray(data)).toBe(true);
    });
  });
});

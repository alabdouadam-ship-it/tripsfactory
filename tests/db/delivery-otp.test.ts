import { describe, it, expect, beforeAll } from 'vitest';
import {
  serviceRoleClient,
  setupTestUsers,
  requester,
  traveler,
} from './setup.js';

describe('Stage 2: Delivery OTP', () => {
  beforeAll(async () => {
    await setupTestUsers();
  });

  it('delivery_code can be set and delivery_code_verified_at updated by booking party', async () => {
    const { data: booking } = await serviceRoleClient
      .from('bookings')
      .insert({
        requester_id: requester.userId,
        traveler_id: traveler.userId,
        price: 10,
        status: 'in_transit',
      })
      .select('id')
      .single();
    expect(booking?.id).toBeDefined();

    const code = '123456';
    const { error: updateCode } = await traveler.client
      .from('bookings')
      .update({ delivery_code: code })
      .eq('id', booking!.id)
      .select()
      .single();
    expect(updateCode).toBeNull();

    const { error: verify } = await requester.client
      .from('bookings')
      .update({
        delivery_code_verified_at: new Date().toISOString(),
      })
      .eq('id', booking!.id)
      .select()
      .single();
    expect(verify).toBeNull();

    const { data: row } = await serviceRoleClient
      .from('bookings')
      .select('delivery_code, delivery_code_verified_at')
      .eq('id', booking!.id)
      .single();
    expect(row?.delivery_code).toBe(code);
    expect(row?.delivery_code_verified_at).toBeTruthy();
  });

  it('non-party cannot set delivery_code_verified_at on booking', async () => {
    const { data: otherBooking } = await serviceRoleClient
      .from('bookings')
      .insert({
        requester_id: traveler.userId,
        traveler_id: traveler.userId,
        price: 10,
        status: 'in_transit',
      })
      .select('id')
      .single();
    expect(otherBooking?.id).toBeDefined();

    const { error } = await requester.client
      .from('bookings')
      .update({
        delivery_code_verified_at: new Date().toISOString(),
      })
      .eq('id', otherBooking!.id)
      .select()
      .single();
    expect(error).toBeTruthy();
  });
});

import { randomUUID } from 'node:crypto';

import { db } from '../../config/database';
import type { AuthenticatedUser } from '../../middleware/requireFirebaseAuth';
import type { BookingResponse, BookingRow, CreateBookingBody } from './booking.types';

function toResponse(row: BookingRow): BookingResponse {
  return {
    id: row.id,
    courtName: row.court_name,
    courtId: row.court_id,
    price: row.price,
    startAt: row.start_at.toISOString(),
    endAt: row.end_at.toISOString(),
    status: row.status,
    createdAt: row.created_at.toISOString(),
  };
}

export async function createBooking(
  user: AuthenticatedUser,
  body: CreateBookingBody,
): Promise<BookingResponse> {
  const { courtName, courtId, price, startAt: startAtRaw } = body;

  if (!courtName || price == null || !startAtRaw) {
    throw new Error('MISSING_FIELDS');
  }

  const startAt = new Date(startAtRaw);
  if (isNaN(startAt.getTime())) {
    throw new Error('INVALID_DATE');
  }
  if (startAt <= new Date()) {
    throw new Error('SLOT_IN_PAST');
  }

  const endAt = new Date(startAt.getTime() + 60 * 60 * 1000);
  const id = randomUUID();

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    // Advisory lock serializes concurrent requests for the exact same slot.
    // hashtext() is 32-bit; cast to bigint is safe. Different slots don't block each other.
    await client.query(`SELECT pg_advisory_xact_lock(hashtext($1)::bigint)`, [
      `${courtName}::${startAt.toISOString()}`,
    ]);

    const conflict = await client.query(
      `SELECT 1 FROM bookings
       WHERE court_name = $1 AND start_at = $2 AND status = 'confirmed'
       LIMIT 1`,
      [courtName, startAt],
    );

    if (conflict.rows.length > 0) {
      throw new Error('SLOT_TAKEN');
    }

    const result = await client.query<BookingRow>(
      `INSERT INTO bookings (id, firebase_uid, court_name, court_id, price, start_at, end_at, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'confirmed')
       RETURNING *`,
      [id, user.firebaseUid, courtName, courtId ?? null, price, startAt, endAt],
    );

    await client.query('COMMIT');
    return toResponse(result.rows[0]);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function getMyAllBookings(user: AuthenticatedUser): Promise<BookingResponse[]> {
  console.log('[booking.service] getMyAllBookings hit — firebaseUid:', user.firebaseUid);

  // Diagnostic: count ALL rows for this uid regardless of status so we can
  // tell "table has no rows for this user" from "rows exist but filtered out".
  const diag = await db.query<{ total: string; statuses: string }>(
    `SELECT count(*)::text AS total,
            coalesce(string_agg(DISTINCT status, ', '), 'none') AS statuses
     FROM bookings
     WHERE firebase_uid = $1`,
    [user.firebaseUid],
  );
  console.log(
    '[booking.service] getMyAllBookings diagnostic — total rows (any status):',
    diag.rows[0]?.total,
    '| statuses present:',
    diag.rows[0]?.statuses,
  );

  const result = await db.query<BookingRow>(
    `SELECT * FROM bookings
     WHERE firebase_uid = $1
       AND status = 'confirmed'
     ORDER BY start_at DESC`,
    [user.firebaseUid],
  );

  console.log('[booking.service] getMyAllBookings — confirmed rows returned:', result.rows.length);
  return result.rows.map(toResponse);
}

export async function getMyUpcomingBookings(user: AuthenticatedUser): Promise<BookingResponse[]> {
  const result = await db.query<BookingRow>(
    `SELECT * FROM bookings
     WHERE firebase_uid = $1
       AND start_at >= now()
       AND status = 'confirmed'
     ORDER BY start_at ASC`,
    [user.firebaseUid],
  );
  return result.rows.map(toResponse);
}

export async function getMyPastBookings(user: AuthenticatedUser): Promise<BookingResponse[]> {
  const result = await db.query<BookingRow>(
    `SELECT * FROM bookings
     WHERE firebase_uid = $1
       AND start_at < now()
       AND status = 'confirmed'
     ORDER BY start_at DESC`,
    [user.firebaseUid],
  );
  return result.rows.map(toResponse);
}

export async function cancelBooking(
  user: AuthenticatedUser,
  bookingId: string,
): Promise<BookingResponse> {
  const existing = await db.query<BookingRow>(
    `SELECT * FROM bookings WHERE id = $1`,
    [bookingId],
  );

  if (existing.rows.length === 0) {
    throw new Error('BOOKING_NOT_FOUND');
  }

  const booking = existing.rows[0];

  if (booking.firebase_uid !== user.firebaseUid) {
    throw new Error('BOOKING_NOT_OWNER');
  }

  if (booking.status === 'cancelled') {
    throw new Error('BOOKING_ALREADY_CANCELLED');
  }

  const result = await db.query<BookingRow>(
    `UPDATE bookings SET status = 'cancelled' WHERE id = $1 RETURNING *`,
    [bookingId],
  );

  return toResponse(result.rows[0]);
}

export async function getCourtDaySlots(
  courtName: string,
  date: string,
): Promise<BookingResponse[]> {
  // Treat the date param as a UTC calendar day (YYYY-MM-DD)
  const dayStart = new Date(`${date}T00:00:00.000Z`);
  if (isNaN(dayStart.getTime())) {
    throw new Error('INVALID_DATE');
  }
  const dayEnd = new Date(dayStart.getTime() + 24 * 60 * 60 * 1000);

  const result = await db.query<BookingRow>(
    `SELECT * FROM bookings
     WHERE court_name = $1
       AND start_at >= $2
       AND start_at < $3
       AND status = 'confirmed'
     ORDER BY start_at ASC`,
    [courtName, dayStart, dayEnd],
  );

  return result.rows.map(toResponse);
}

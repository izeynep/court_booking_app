import type { Request, Response } from 'express';

import {
  cancelBooking,
  createBooking,
  getCourtDaySlots,
  getMyAllBookings,
  getMyPastBookings,
  getMyUpcomingBookings,
} from './booking.service';
import type { CreateBookingBody } from './booking.types';

export async function postBooking(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Authentication required.' } });
    return;
  }

  try {
    const booking = await createBooking(req.user, req.body as CreateBookingBody);
    res.status(201).json(booking);
  } catch (error) {
    if (error instanceof Error) {
      switch (error.message) {
        case 'MISSING_FIELDS':
          res.status(400).json({
            error: { code: 'MISSING_FIELDS', message: 'courtName, price, and startAt are required.' },
          });
          return;
        case 'INVALID_DATE':
          res.status(400).json({
            error: { code: 'INVALID_DATE', message: 'startAt must be a valid ISO datetime string.' },
          });
          return;
        case 'SLOT_IN_PAST':
          res.status(400).json({
            error: { code: 'SLOT_IN_PAST', message: 'Cannot book a slot in the past.' },
          });
          return;
        case 'SLOT_TAKEN':
          res.status(409).json({
            error: { code: 'SLOT_TAKEN', message: 'This slot is already booked.' },
          });
          return;
      }
    }
    throw error;
  }
}

export async function getMyAllBookingsHandler(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Authentication required.' } });
    return;
  }

  const bookings = await getMyAllBookings(req.user);
  res.status(200).json(bookings);
}

export async function getMyUpcomingBookingsHandler(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Authentication required.' } });
    return;
  }

  const bookings = await getMyUpcomingBookings(req.user);
  res.status(200).json(bookings);
}

export async function getMyPastBookingsHandler(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Authentication required.' } });
    return;
  }

  const bookings = await getMyPastBookings(req.user);
  res.status(200).json(bookings);
}

export async function deleteBooking(req: Request, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Authentication required.' } });
    return;
  }

  try {
    const booking = await cancelBooking(req.user, req.params.id);
    res.status(200).json(booking);
  } catch (error) {
    if (error instanceof Error) {
      switch (error.message) {
        case 'BOOKING_NOT_FOUND':
          res.status(404).json({
            error: { code: 'BOOKING_NOT_FOUND', message: 'Booking not found.' },
          });
          return;
        case 'BOOKING_NOT_OWNER':
          res.status(403).json({
            error: { code: 'BOOKING_NOT_OWNER', message: 'You can only cancel your own bookings.' },
          });
          return;
        case 'BOOKING_ALREADY_CANCELLED':
          res.status(409).json({
            error: { code: 'BOOKING_ALREADY_CANCELLED', message: 'This booking is already cancelled.' },
          });
          return;
      }
    }
    throw error;
  }
}

export async function getCourtDaySlotsHandler(req: Request, res: Response): Promise<void> {
  try {
    const slots = await getCourtDaySlots(req.params.courtName, req.params.date);
    res.status(200).json(slots);
  } catch (error) {
    if (error instanceof Error && error.message === 'INVALID_DATE') {
      res.status(400).json({
        error: { code: 'INVALID_DATE', message: 'date must be in YYYY-MM-DD format.' },
      });
      return;
    }
    throw error;
  }
}

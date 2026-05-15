import { Router } from 'express';

import { asyncHandler } from '../../middleware/asyncHandler';
import { requireFirebaseAuth } from '../../middleware/requireFirebaseAuth';
import {
  deleteBooking,
  getCourtDaySlotsHandler,
  getMyAllBookingsHandler,
  getMyPastBookingsHandler,
  getMyUpcomingBookingsHandler,
  postBooking,
} from './booking.controller';

export const bookingRouter = Router();

bookingRouter.post('/', requireFirebaseAuth, asyncHandler(postBooking));
bookingRouter.get('/my', requireFirebaseAuth, asyncHandler(getMyAllBookingsHandler));
bookingRouter.get('/my/upcoming', requireFirebaseAuth, asyncHandler(getMyUpcomingBookingsHandler));
bookingRouter.get('/my/past', requireFirebaseAuth, asyncHandler(getMyPastBookingsHandler));
bookingRouter.delete('/:id', requireFirebaseAuth, asyncHandler(deleteBooking));
bookingRouter.get(
  '/court/:courtName/day/:date',
  requireFirebaseAuth,
  asyncHandler(getCourtDaySlotsHandler),
);

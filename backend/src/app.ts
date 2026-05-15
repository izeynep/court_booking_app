import cors from 'cors';
import express from 'express';

import { assistantRouter } from './modules/assistant/assistant.routes';
import { bookingRouter } from './modules/bookings/booking.routes';
import { errorHandler } from './middleware/errorHandler';

export function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/health', (_req, res) => {
    res.status(200).json({ ok: true });
  });

  app.use('/v1/assistant', assistantRouter);
  app.use('/v1/bookings', bookingRouter);

  app.use(errorHandler);

  return app;
}

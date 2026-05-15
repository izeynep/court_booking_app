import { Router } from 'express';

import { asyncHandler } from '../../middleware/asyncHandler';
import { requireFirebaseAuth } from '../../middleware/requireFirebaseAuth';

import { postAssistantChat } from './assistant.controller';

export const assistantRouter = Router();

assistantRouter.post(
  '/chat',
  requireFirebaseAuth,
  asyncHandler(postAssistantChat),
);

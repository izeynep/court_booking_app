import type { Request, Response } from 'express';

import { handleAssistantChat } from './assistant.service';
import type { AssistantChatRequest } from './assistant.types';

export async function postAssistantChat(
  req: Request,
  res: Response,
): Promise<void> {
  if (!req.user) {
    res.status(401).json({
      error: {
        code: 'UNAUTHORIZED',
        message: 'Authentication is required.',
      },
    });
    return;
  }

  try {
    const body = req.body as AssistantChatRequest;
    const response = await handleAssistantChat(req.user, body);
    res.status(200).json(response);
  } catch (error) {
    if (error instanceof Error && error.message === 'EMPTY_MESSAGE') {
      res.status(400).json({
        error: {
          code: 'EMPTY_MESSAGE',
          message: 'Message is required.',
        },
      });
      return;
    }

    throw error;
  }
}

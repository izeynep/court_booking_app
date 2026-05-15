import type { AuthenticatedUser } from '../../middleware/requireFirebaseAuth';
import { generateAssistantReply } from '../../providers/llmProvider';

import { buildAssistantContextPrompt } from './assistant_context_builder';
import type {
  AssistantChatRequest,
  AssistantChatResponse,
} from './assistant.types';

export async function handleAssistantChat(
  user: AuthenticatedUser,
  body: AssistantChatRequest,
): Promise<AssistantChatResponse> {
  const message = body.message?.trim();

  if (!message) {
    throw new Error('EMPTY_MESSAGE');
  }

  const contextPrompt = await buildAssistantContextPrompt(user, body);

  const reply = await generateAssistantReply({
    contextPrompt,
    userId: user.firebaseUid,
    userMessage: message,
  });

  return {
    conversationId: body.conversationId ?? null,
    message: {
      id: null,
      role: 'assistant',
      content: reply.content,
      createdAt: new Date().toISOString(),
    },
    suggestions: [
      'Siradaki rezervasyonumu goster',
      'Oynamak icin iyi bir zaman bul',
      'Yakinda hangi etkinlikler var?',
    ],
  };
}

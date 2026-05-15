export type AssistantChatRequest = {
  message?: string;
  conversationId?: string | null;
  context?: {
    screen?: string;
    locale?: string;
    timezone?: string;
  };
};

export type AssistantChatResponse = {
  conversationId: string | null;
  message: {
    id: string | null;
    role: 'assistant';
    content: string;
    createdAt: string;
  };
  suggestions: string[];
};

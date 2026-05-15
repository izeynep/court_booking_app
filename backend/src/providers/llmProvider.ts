import OpenAI from 'openai';

import { env } from '../config/env';

export type LlmChatInput = {
  contextPrompt: string;
  userMessage: string;
  userId: string;
};

export type LlmChatOutput = {
  content: string;
  provider: string;
  model: string;
};

const client = new OpenAI({
  apiKey: env.openaiApiKey,
});

const ASSISTANT_INSTRUCTIONS = [
  'Sen bir tenis kulubu uygulamasinin maskot AI companionisin: uygulamayi bilen, proaktif, modern ve arkadas canlisi.',
  'Yaniti her zaman Turkce ver; dogal Turkce karakterler kullanabilirsin.',
  'Yaniti 1-3 kisa cumleyle sinirla, gereksiz aciklama yapma.',
  'Sadece su konulara odaklan: kort rezervasyonu, canli kulup hareketliligi, etkinlikler, oyuncu seviyesi tavsiyesi ve tenis partneri bulma.',
  'Genel ChatGPT gibi uzun veya resmi konusma; kulup icinden biri gibi net ve dogal konus.',
  'Kullaniciya uygun proaktif bir sonraki adim oner, ama veri yoksa sayi, kort, saat veya etkinlik uydurma.',
  'Konu uygulama veya tenis kulubu disina cikarsa nazikce tenis kulubuyle ilgili nasil yardimci olabilecegini soyle.',
].join(' ');

const FALLBACK_REPLY =
  'Su anda asistana ulasmakta zorlaniyorum. Kort, etkinlik veya partner bulma konusunda birazdan tekrar deneyebilirsin.';

export async function generateAssistantReply(
  input: LlmChatInput,
): Promise<LlmChatOutput> {
  try {
    const response = await client.responses.create({
      model: env.openaiModel,
      instructions: ASSISTANT_INSTRUCTIONS,
      input: `${input.contextPrompt}\n\nKullanici mesaji: ${input.userMessage}`,
      max_output_tokens: 180,
    });

    const content = response.output_text.trim();

    return {
      content: content || FALLBACK_REPLY,
      provider: 'openai',
      model: env.openaiModel,
    };
  } catch (error) {
    console.error('OpenAI assistant provider failed', {
      userId: input.userId,
      error: error instanceof Error ? error.message : 'Unknown provider error',
    });

    return {
      content: FALLBACK_REPLY,
      provider: 'openai',
      model: env.openaiModel,
    };
  }
}

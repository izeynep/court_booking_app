import type { AuthenticatedUser } from '../../middleware/requireFirebaseAuth';
import { db } from '../../config/database';

import type { AssistantChatRequest } from './assistant.types';

type AssistantContext = {
  profileStats: string;
  activityLevel: string;
  eventParticipation: string;
  bookingHabits: string;
  timeOfDay: string;
  screen: string;
};

function timeOfDayLabel(date: Date): string {
  const hour = date.getHours();
  if (hour >= 5 && hour < 12) return 'sabah';
  if (hour >= 12 && hour < 17) return 'ogleden sonra';
  if (hour >= 17 && hour < 22) return 'aksam';
  return 'gece';
}

function activityLevelFromAssistantMessages(count: number): string {
  if (count >= 12) return 'uygulamayla sik etkilesimde';
  if (count >= 4) return 'uygulamayi ara ara kullaniyor';
  if (count >= 1) return 'uygulamayi yeni yeni deniyor';
  return 'yeni veya sessiz kullanici';
}

async function readAssistantUsage(firebaseUid: string): Promise<number> {
  const result = await db.query<{ message_count: string }>(
    `
      select count(am.id)::text as message_count
      from users u
      left join assistant_conversations ac on ac.user_id = u.id
      left join assistant_messages am on am.conversation_id = ac.id
      where u.firebase_uid = $1
    `,
    [firebaseUid],
  );

  return Number(result.rows[0]?.message_count ?? 0);
}

async function buildContextData(
  user: AuthenticatedUser,
  request: AssistantChatRequest,
): Promise<AssistantContext> {
  const now = new Date();
  const assistantMessageCount = await readAssistantUsage(user.firebaseUid);
  const displayName = user.name ?? user.email ?? 'isimsiz uye';

  return {
    profileStats: `uye: ${displayName}; firebase_uid var; kayitli profil detaylari sinirli`,
    activityLevel: activityLevelFromAssistantMessages(assistantMessageCount),
    eventParticipation:
      'etkinlik katilim verisi henuz backend veri modelinde yok; kesin sayi uydurma',
    bookingHabits:
      'rezervasyon gecmisi henuz backend veri modelinde yok; kesin saat veya kort uydurma',
    timeOfDay: timeOfDayLabel(now),
    screen: request.context?.screen ?? 'unknown',
  };
}

export async function buildAssistantContextPrompt(
  user: AuthenticatedUser,
  request: AssistantChatRequest,
): Promise<string> {
  const context = await buildContextData(user, request);

  return [
    'Uygulama baglami:',
    `- Profil: ${context.profileStats}`,
    `- Aktivite seviyesi: ${context.activityLevel}`,
    `- Etkinlik katilimi: ${context.eventParticipation}`,
    `- Rezervasyon aliskanligi: ${context.bookingHabits}`,
    `- Zaman: ${context.timeOfDay}`,
    `- Ekran: ${context.screen}`,
    'Bu baglami kullanarak kisa, proaktif ve kisila yakin bir oneride bulun. Veri yoksa uydurma; nazikce tercih sor.',
  ].join('\n');
}

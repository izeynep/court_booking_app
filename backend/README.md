# Court Booking Assistant API

Separate backend for the Flutter tennis app assistant.

Current phase:

- Node.js
- Express
- TypeScript
- PostgreSQL connection setup
- Firebase Admin token verification
- OpenAI-backed LLM provider wrapper
- `POST /v1/assistant/chat`

The Flutter app should never call an LLM provider directly. It should call this API with a Firebase ID token:

```http
Authorization: Bearer <firebase-id-token>
```

## Setup

```bash
npm install
cp .env.example .env
npm run dev
```

Place a Firebase service account JSON file at the path configured by `FIREBASE_SERVICE_ACCOUNT_PATH`, or use `GOOGLE_APPLICATION_CREDENTIALS`.
Set `OPENAI_API_KEY` in the backend `.env` file. `OPENAI_MODEL` defaults to the value shown in `.env.example`.

## Endpoint

```http
POST /v1/assistant/chat
Content-Type: application/json
Authorization: Bearer <firebase-id-token>
```

```json
{
  "message": "What should I play this week?",
  "conversationId": null,
  "context": {
    "screen": "home",
    "locale": "en-US",
    "timezone": "Europe/Istanbul"
  }
}
```

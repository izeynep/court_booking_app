# Court Booking AI 🎾

AI-powered realtime tennis club mobile application built with Flutter, Firebase, Node.js, Express, and PostgreSQL.

## Features

- Realtime court booking
- Live club activity map
- Events & social matching
- AI mascot assistant
- Personalized player analytics
- Firebase authentication
- REST API backend
- PostgreSQL-powered assistant memory

---

## Tech Stack

### Frontend
- Flutter

### Backend
- Node.js
- Express
- TypeScript

### Database
- PostgreSQL

### Services
- Firebase
- OpenAI API

---

## Architecture

Flutter App  
→ REST API (Node/Express)  
→ PostgreSQL  
→ AI Assistant Layer

---

## Flutter Setup

```bash
flutter pub get
flutter run
```

---

## Backend Setup

```bash
cd backend
npm install
npm run dev
```

Create:

```txt
backend/.env
```

Paste:

```env
PORT=3000

DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/tennis_ai

OPENAI_API_KEY=your_openai_api_key

OPENAI_MODEL=gpt-4.1-mini

FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
```

Also place your Firebase Admin SDK JSON file inside:

```txt
backend/serviceAccountKey.json
```

---

## Status

Currently in active development 🚀
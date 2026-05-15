import fs from 'node:fs';

import admin from 'firebase-admin';

import { env } from './env';

function getCredential(): admin.credential.Credential {
  if (env.firebaseServiceAccountPath) {
    const raw = fs.readFileSync(env.firebaseServiceAccountPath, 'utf8');
    const serviceAccount = JSON.parse(raw);
    return admin.credential.cert(serviceAccount);
  }

  return admin.credential.applicationDefault();
}

export function initializeFirebaseAdmin(): void {
  if (admin.apps.length > 0) return;

  admin.initializeApp({
    credential: getCredential(),
  });
}

export const firebaseAdmin = admin;

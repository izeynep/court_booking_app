import { env } from './config/env';
import { checkDatabaseConnection } from './config/database';
import { initializeFirebaseAdmin } from './config/firebase';
import { createApp } from './app';

async function main(): Promise<void> {
  initializeFirebaseAdmin();
  await checkDatabaseConnection();

  const app = createApp();

  app.listen(env.port, () => {
    console.log(`Assistant API listening on port ${env.port}`);
  });
}

main().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});

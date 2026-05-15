import { Pool } from 'pg';

import { env } from './env';

export const db = new Pool({
  connectionString: env.databaseUrl,
});

export async function checkDatabaseConnection(): Promise<void> {
  const client = await db.connect();
  try {
    await client.query('select 1');
  } finally {
    client.release();
  }
}

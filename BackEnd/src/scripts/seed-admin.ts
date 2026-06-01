/**
 * @file seed-admin.ts
 * @description Script de seed para crear el usuario administrador del sistema.
 * Email y password se leen de las env vars ADMIN_EMAIL y ADMIN_PASSWORD
 * (con fallback a valores por defecto solo fuera de producción). En producción
 * (NODE_ENV=production) ambas variables son obligatorias o el script aborta.
 * Idempotente: no hace nada si el usuario ya existe.
 *
 * Uso: npm run seed:admin
 *
 * @module Auth
 * @layer Data
 */

import 'dotenv/config';
import { MongoClient, ObjectId } from 'mongodb';
import bcrypt from 'bcryptjs';

// ─── Configuración ────────────────────────────────────────────────────────────

const MONGODB_URI =
  process.env.MONGODB_URI ?? 'mongodb://localhost:27017/plants';
const DB_NAME = MONGODB_URI.split('/').pop()?.split('?')[0] ?? 'plants';

const IS_PRODUCTION = process.env.NODE_ENV === 'production';

// Defaults solo aptos para desarrollo local. En producción son inaceptables:
// si no se han definido ADMIN_EMAIL/ADMIN_PASSWORD explícitamente, abortamos
// antes de crear un admin con credenciales conocidas y públicas.
const DEFAULT_ADMIN_EMAIL = 'admin@plants.app';
const DEFAULT_ADMIN_PASSWORD = 'admin1234';

if (
  IS_PRODUCTION &&
  (!process.env.ADMIN_EMAIL || !process.env.ADMIN_PASSWORD)
) {
  console.error(
    '❌ seed-admin: en producción (NODE_ENV=production) debes definir las variables ' +
      'de entorno ADMIN_EMAIL y ADMIN_PASSWORD.\n' +
      '   Negándose a crear un admin con las credenciales por defecto, que son públicas.',
  );
  process.exit(1);
}

// Credenciales del admin: leer de env vars, con defaults solo para dev local.
const ADMIN_EMAIL = process.env.ADMIN_EMAIL ?? DEFAULT_ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? DEFAULT_ADMIN_PASSWORD;
const ADMIN_NAME = 'Admin';
const BCRYPT_ROUNDS = 10;

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log(`📍 Conectando a MongoDB: ${DB_NAME}...`);

  const client = new MongoClient(MONGODB_URI);
  await client.connect();

  const db = client.db(DB_NAME);
  const collection = db.collection('users');

  try {
    // Comprobar si el admin ya existe (incluye deletedAt para evitar conflictos de índice único).
    const existing = await collection.findOne({ email: ADMIN_EMAIL });

    if (existing) {
      if (existing.deletedAt) {
        // Restaurar y actualizar el rol por si acaso.
        await collection.updateOne(
          { email: ADMIN_EMAIL },
          { $set: { role: 'admin', deletedAt: null, updatedAt: new Date() } },
        );
        console.log(`  ♻️  Admin restaurado y actualizado: ${ADMIN_EMAIL}`);
      } else {
        // Asegurarse de que tiene rol admin aunque se haya creado sin él.
        if (existing.role !== 'admin') {
          await collection.updateOne(
            { email: ADMIN_EMAIL },
            { $set: { role: 'admin', updatedAt: new Date() } },
          );
          console.log(`  🔑 Rol actualizado a 'admin' para: ${ADMIN_EMAIL}`);
        } else {
          console.log(`  ⏭  Ya existe y es admin: ${ADMIN_EMAIL}`);
        }
      }
    } else {
      // Crear el usuario admin desde cero.
      const passwordHash = await bcrypt.hash(ADMIN_PASSWORD, BCRYPT_ROUNDS);
      const now = new Date();

      await collection.insertOne({
        _id: new ObjectId(),
        role: 'admin',
        name: ADMIN_NAME,
        email: ADMIN_EMAIL,
        passwordHash,
        preferences: {
          appearInChatSearch: true,
          considerWeatherByDefault: false,
          isPrivate: false,
        },
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      });

      console.log(`  ✅ Admin creado: ${ADMIN_EMAIL}`);
    }

    console.log('\n📌 Seed admin completado.');
  } finally {
    await client.close();
  }
}

main().catch((err) => {
  console.error('❌ Error en seed-admin:', err);
  process.exit(1);
});

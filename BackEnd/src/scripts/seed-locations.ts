/**
 * @file seed-locations.ts
 * @description Script de seed para insertar las 52 capitales de provincia de España en MongoDB.
 * Reutiliza el catálogo estático de SPAIN_LOCATIONS (mismo que el LocationController).
 * Solo inserta las entradas que aún no existan (idempotente por nombre).
 *
 * Uso: npx tsx src/scripts/seed-locations.ts
 *
 * @module User
 * @layer Data
 */

import 'dotenv/config';
import { MongoClient } from 'mongodb';
import { SPAIN_LOCATIONS } from '../data/static/spain-locations';

// ─── Configuración ────────────────────────────────────────────────────────────

const MONGODB_URI = process.env.MONGODB_URI ?? 'mongodb://localhost:27017/plants';
const DB_NAME     = MONGODB_URI.split('/').pop()?.split('?')[0] ?? 'plants';
const COLLECTION  = 'locations';

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log(`📍 Conectando a MongoDB: ${DB_NAME}...`);
  const client = new MongoClient(MONGODB_URI);

  try {
    await client.connect();
    const db  = client.db(DB_NAME);
    const col = db.collection(COLLECTION);

    let inserted = 0;
    let skipped  = 0;

    for (const loc of SPAIN_LOCATIONS) {
      // Idempotente: no insertar si ya existe una entrada con el mismo nombre.
      const exists = await col.findOne({ name: loc.name });

      if (exists) {
        console.log(`  ⏭  Ya existe: ${loc.name}`);
        skipped++;
      } else {
        await col.insertOne({
          name:     loc.name,
          fullName: loc.fullName,
          lat:      loc.lat,
          lon:      loc.lon,
        });
        console.log(`  ✅ Insertada: ${loc.fullName}`);
        inserted++;
      }
    }

    console.log(`\n📌 Seed completado — ${inserted} insertadas, ${skipped} omitidas.`);
  } finally {
    await client.close();
  }
}

main().catch((err) => {
  console.error('❌ Error en seed-locations:', err);
  process.exit(1);
});

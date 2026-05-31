/**
 * @file seed-species.ts
 * @description Script de seed para insertar especies de plantas de prueba en MongoDB.
 * Inserta 14 especies públicas con careRequirements completos (wateringDays, lightNeed, temperatureRange).
 * Tres de ellas (Limonero, Tomatera, Fresa) incluyen produceFruit=true y harvestMonths para notificaciones de cosecha.
 * Fresa cubre los meses de primavera [3,4,5,6] para que el cron _processHarvest() dispare en marzo durante el demo.
 * Solo inserta las especies que aún no existan (idempotente por nombre).
 *
 * Uso: npx tsx src/scripts/seed-species.ts
 *      (o: node --loader ts-node/esm src/scripts/seed-species.ts)
 *
 * @module Plants
 * @layer Data
 */

import 'dotenv/config';
import { MongoClient, Int32 } from 'mongodb';

// ─── Configuración ────────────────────────────────────────────────────────────

const MONGODB_URI = process.env.MONGODB_URI ?? 'mongodb://localhost:27017/plants';
const DB_NAME     = MONGODB_URI.split('/').pop()?.split('?')[0] ?? 'plants';
const COLLECTION  = 'plant_species';

// ─── Datos de especies de prueba ──────────────────────────────────────────────

const now = new Date();

/**
 * Especies de prueba para el catálogo de la aplicación.
 * Cubre distintos niveles de luz, frecuencias de riego y climas.
 */
const SPECIES_SEED = [
  {
    name:           'Monstera',
    scientificName: 'Monstera deliciosa',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(7),
      lightNeed:        'Medium',
      temperatureRange: { min: 18, max: 30 },
    },
    climateCompatibility: ['Tropical', 'Subtropical'],
    tips: [
      'Limpia las hojas con un paño húmedo para mantener la fotosíntesis activa.',
      'Evita el sol directo intenso — quema las hojas.',
    ],
    isPublic:                    true,
    requiresPruning:             false,
    // verano: regar cada ~5 días; invierno: cada ~9 días.
    seasonalWateringAdjustment:  { summer: 0.7, winter: 1.3 },
    minRainfallMm:               10,
    waterLitersPerWatering:      1.5,
    auditHistory:                [],
    createdAt:                   now,
    updatedAt:                   now,
  },
  {
    name:           'Pothos',
    scientificName: 'Epipremnum aureum',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(10),
      lightNeed:        'Low',
      temperatureRange: { min: 15, max: 30 },
    },
    climateCompatibility: ['Tropical', 'Subtropical', 'Templado'],
    tips: [
      'Tolera poca luz y es ideal para interiores.',
      'Deja secar la tierra entre riegos para evitar podredumbre de raíces.',
    ],
    isPublic:        true,
    requiresPruning: false,
    minRainfallMm:   8,
    waterLitersPerWatering: 0.7,
    auditHistory:    [],
    createdAt:       now,
    updatedAt:       now,
  },
  {
    name:           'Cactus',
    scientificName: 'Cactaceae spp.',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(21),
      lightNeed:        'High',
      temperatureRange: { min: 10, max: 40 },
    },
    climateCompatibility: ['Árido', 'Semiárido'],
    tips: [
      'Riega muy poco en invierno — el cactus entra en letargo.',
      'Necesita sol directo varias horas al día.',
    ],
    isPublic:                   true,
    requiresPruning:            false,
    // invierno: casi suspensión vegetativa (~63 días entre riegos).
    seasonalWateringAdjustment: { winter: 3.0 },
    minRainfallMm:              2,
    waterLitersPerWatering:     0.2,
    auditHistory:               [],
    createdAt:                  now,
    updatedAt:                  now,
  },
  {
    name:           'Helecho Boston',
    scientificName: 'Nephrolepis exaltata',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(3),
      lightNeed:        'Low',
      temperatureRange: { min: 16, max: 24 },
    },
    climateCompatibility: ['Tropical', 'Templado Húmedo'],
    tips: [
      'Mantén la tierra siempre ligeramente húmeda.',
      'Pulveriza las hojas con agua para aumentar la humedad ambiental.',
    ],
    isPublic:                   true,
    requiresPruning:            false,
    // verano: regar cada ~2 días; invierno: cada ~4-5 días.
    seasonalWateringAdjustment: { summer: 0.7, winter: 1.5 },
    minRainfallMm:              5,
    waterLitersPerWatering:     1.0,
    auditHistory:               [],
    createdAt:                  now,
    updatedAt:                  now,
  },
  {
    name:           'Rosa',
    scientificName: 'Rosa spp.',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(5),
      lightNeed:        'High',
      temperatureRange: { min: 10, max: 28 },
    },
    climateCompatibility: ['Templado', 'Mediterráneo'],
    tips: [
      'Poda los tallos muertos para estimular nuevas flores.',
      'Riega en la base, evita mojar las hojas para prevenir hongos.',
    ],
    isPublic:                   true,
    requiresPruning:            true,
    pruningMonths:               [new Int32(2)],
    // verano: regar cada ~4 días; invierno: cada ~7 días.
    seasonalWateringAdjustment: { summer: 0.7, winter: 1.4 },
    minRainfallMm:              8,
    waterLitersPerWatering:     1.5,
    auditHistory:               [],
    createdAt:                  now,
    updatedAt:                  now,
  },
  {
    name:           'Sansevieria',
    scientificName: 'Dracaena trifasciata',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(14),
      lightNeed:        'Low',
      temperatureRange: { min: 15, max: 35 },
    },
    climateCompatibility: ['Tropical', 'Árido', 'Templado'],
    tips: [
      'Es una de las plantas más resistentes — casi indestructible.',
      'El exceso de riego es el principal enemigo de la sansevieria.',
    ],
    isPublic:        true,
    requiresPruning: false,
    minRainfallMm:   5,
    waterLitersPerWatering: 0.5,
    auditHistory:    [],
    createdAt:       now,
    updatedAt:       now,
  },
  {
    name:           'Lavanda',
    scientificName: 'Lavandula angustifolia',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(10),
      lightNeed:        'High',
      temperatureRange: { min: 5, max: 30 },
    },
    climateCompatibility: ['Mediterráneo', 'Templado'],
    tips: [
      'Prefiere suelos bien drenados — no tolera el encharcamiento.',
      'Poda después de la floración para mantener la forma compacta.',
    ],
    isPublic:                   true,
    requiresPruning:            true,
    pruningMonths:               [new Int32(3)],
    // verano: regar cada ~8 días; invierno: cada ~15 días.
    seasonalWateringAdjustment: { summer: 0.8, winter: 1.5 },
    minRainfallMm:              3,
    waterLitersPerWatering:     0.5,
    auditHistory:               [],
    createdAt:                  now,
    updatedAt:                  now,
  },
  {
    name:           'Ficus lyrata',
    scientificName: 'Ficus lyrata',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(7),
      lightNeed:        'Medium',
      temperatureRange: { min: 18, max: 30 },
    },
    climateCompatibility: ['Tropical', 'Subtropical'],
    tips: [
      'No muevas el ficus una vez que esté aclimatado — le afecta el cambio de ubicación.',
      'Riega cuando los primeros 3 cm de tierra estén secos.',
    ],
    isPublic:                   true,
    requiresPruning:            false,
    // verano: regar cada ~5 días; invierno: cada ~9 días.
    seasonalWateringAdjustment: { summer: 0.7, winter: 1.3 },
    minRainfallMm:              10,
    waterLitersPerWatering:     1.5,
    auditHistory:               [],
    createdAt:                  now,
    updatedAt:                  now,
  },
  {
    name:           'Orquídea Phalaenopsis',
    scientificName: 'Phalaenopsis spp.',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(7),
      lightNeed:        'Medium',
      temperatureRange: { min: 18, max: 28 },
    },
    climateCompatibility: ['Tropical', 'Subtropical'],
    tips: [
      'Riega sumergiendo la maceta en agua 15 minutos, una vez por semana.',
      'Luz indirecta brillante — el sol directo quema las hojas.',
    ],
    isPublic:        true,
    requiresPruning: false,
    minRainfallMm:   5,
    waterLitersPerWatering: 0.3,
    auditHistory:    [],
    createdAt:       now,
    updatedAt:       now,
  },
  {
    name:           'Aloe Vera',
    scientificName: 'Aloe barbadensis miller',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(14),
      lightNeed:        'High',
      temperatureRange: { min: 13, max: 38 },
    },
    climateCompatibility: ['Árido', 'Mediterráneo', 'Subtropical'],
    tips: [
      'Usa tierra de cactus o añade perlita para mejorar el drenaje.',
      'El gel interior es útil para quemaduras leves de piel.',
    ],
    isPublic:                   true,
    requiresPruning:            false,
    produceFruit:               false,
    // verano: regar cada ~10 días; invierno: suspensión casi total (~28 días).
    seasonalWateringAdjustment: { summer: 0.7, winter: 2.0 },
    minRainfallMm:              3,
    waterLitersPerWatering:     0.4,
    auditHistory:               [],
    createdAt:                  now,
    updatedAt:                  now,
  },
  {
    name:           'Limonero',
    scientificName: 'Citrus limon',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(7),
      lightNeed:        'High',
      temperatureRange: { min: 10, max: 35 },
    },
    climateCompatibility: ['Mediterráneo', 'Subtropical'],
    tips: [
      'Necesita al menos 6-8 horas de sol directo al día para fructificar bien.',
      'Riega con regularidad pero evita el encharcamiento — buena tolerancia a sequía breve.',
      'Abona con fertilizante rico en potasio durante la primavera para mejorar la cosecha.',
    ],
    isPublic:        true,
    requiresPruning: true,
    pruningMonths:    [new Int32(3)],
    produceFruit:    true,
    harvestMonths:   [new Int32(11), new Int32(12), new Int32(1), new Int32(2)],
    minRainfallMm:   10,
    waterLitersPerWatering: 3.0,
    auditHistory:    [],
    createdAt:       now,
    updatedAt:       now,
  },
  {
    name:           'Tomatera',
    scientificName: 'Solanum lycopersicum',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(2),
      lightNeed:        'High',
      temperatureRange: { min: 15, max: 35 },
    },
    climateCompatibility: ['Mediterráneo', 'Templado', 'Subtropical'],
    tips: [
      'Riega de forma regular y constante — los cambios bruscos causan rajaduras en los frutos.',
      'Coloca tutores o estacas para sostener las ramas cargadas de tomates.',
      'Elimina los brotes axilares ("chupones") para concentrar la energía en los frutos.',
    ],
    isPublic:                   true,
    requiresPruning:            false,
    produceFruit:               true,
    harvestMonths:              [new Int32(6), new Int32(7), new Int32(8), new Int32(9)],
    // verano: necesita riego frecuente para producir frutos (~1-2 días).
    seasonalWateringAdjustment: { summer: 0.7 },
    minRainfallMm:              8,
    waterLitersPerWatering:     1.5,
    auditHistory:               [],
    createdAt:       now,
    updatedAt:       now,
  },
  {
    name:           'Fresa',
    scientificName: 'Fragaria × ananassa',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(3),
      lightNeed:        'High',
      temperatureRange: { min: 10, max: 28 },
    },
    climateCompatibility: ['Templado', 'Mediterráneo'],
    tips: [
      'Riega con regularidad — la fresa necesita humedad constante pero sin encharcamiento.',
      'Retira los estolones si quieres concentrar la energía en los frutos.',
      'Cubre el suelo con paja para mantener la humedad y evitar que los frutos toquen la tierra.',
    ],
    isPublic:        true,
    requiresPruning: false,
    produceFruit:    true,
    // TFG: cubre los meses de primavera para que _processHarvest() dispare durante el demo (marzo 2026).
    harvestMonths:   [new Int32(3), new Int32(4), new Int32(5), new Int32(6)],
    minRainfallMm:   5,
    waterLitersPerWatering: 0.8,
    auditHistory:    [],
    createdAt:       now,
    updatedAt:       now,
  },
  {
    name:           'Test',
    scientificName: 'Testus maximus',
    image:          '',
    careRequirements: {
      wateringDays:     new Int32(1),
      lightNeed:        'Medium',
      temperatureRange: { min: 0, max: 50 },
    },
    climateCompatibility: ['Todos'],
    tips: [
      'Especie de pruebas para testing de funcionalidades.',
    ],
    isPublic:                   true,
    requiresPruning:            true,
    // Poda todos los meses (1–12) para que _processPruning() dispare siempre.
    pruningMonths:              Array.from({ length: 12 }, (_, i) => new Int32(i + 1)),
    produceFruit:               true,
    // Cosecha todos los meses (1–12) para que _processHarvest() dispare siempre.
    harvestMonths:              Array.from({ length: 12 }, (_, i) => new Int32(i + 1)),
    // Sin ajuste estacional (siempre riego diario).
    seasonalWateringAdjustment: { summer: 1.0, winter: 1.0 },
    minRainfallMm:              1,
    waterLitersPerWatering:     0.5,
    auditHistory:               [],
    createdAt:                  now,
    updatedAt:                  now,
  },
];

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log(`🌿 Conectando a MongoDB: ${DB_NAME}...`);
  const client = new MongoClient(MONGODB_URI);

  try {
    await client.connect();
    const db  = client.db(DB_NAME);
    const col = db.collection(COLLECTION);

    let inserted = 0;
    let updated  = 0;

    for (const species of SPECIES_SEED) {
      // Idempotente: si ya existe, actualizar solo los campos evolutivos (campos añadidos
      // en fases posteriores que podrían faltar en documentos creados antes).
      const exists = await col.findOne({ name: species.name, deletedAt: { $exists: false } });

      if (exists) {
        // Construir $set solo con los campos que podrían no existir en la BD.
        const patch: Record<string, unknown> = { updatedAt: new Date() };
        if (species.seasonalWateringAdjustment !== undefined) patch['seasonalWateringAdjustment'] = species.seasonalWateringAdjustment;
        if (species.requiresPruning !== undefined)            patch['requiresPruning']            = species.requiresPruning;
        if (species.pruningMonths    !== undefined)            patch['pruningMonths']               = species.pruningMonths;
        if (species.produceFruit    !== undefined)            patch['produceFruit']               = species.produceFruit;
        if (species.harvestMonths   !== undefined)            patch['harvestMonths']              = species.harvestMonths;
        if ((species as { minRainfallMm?: number }).minRainfallMm !== undefined) patch['minRainfallMm'] = (species as { minRainfallMm?: number }).minRainfallMm;
        if ((species as { waterLitersPerWatering?: number }).waterLitersPerWatering !== undefined) patch['waterLitersPerWatering'] = (species as { waterLitersPerWatering?: number }).waterLitersPerWatering;
        // Eliminar campo legacy `pruningMonth` (migrado a `pruningMonths` array).
        await col.updateOne({ name: species.name }, { $set: patch, $unset: { pruningMonth: '' } });
        console.log(`  🔄 Actualizada: ${species.name}`);
        updated++;
      } else {
        await col.insertOne(species);
        console.log(`  ✅ Insertada: ${species.name} (${species.scientificName})`);
        inserted++;
      }
    }

    console.log(`\n🌱 Seed completado — ${inserted} insertadas, ${updated} actualizadas.`);
  } finally {
    await client.close();
  }
}

main().catch((err) => {
  console.error('❌ Error en seed-species:', err);
  process.exit(1);
});

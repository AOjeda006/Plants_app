/**
 * @file database.config.ts
 * @description Configuración de la conexión a MongoDB y definición de índices por defecto.
 * @module Core
 * @layer Core
 */

import 'dotenv/config';

/**
 * Interfaz de configuración de la base de datos.
 */
export interface DatabaseConfig {
  /** URI de conexión a MongoDB */
  uri: string;
  /** Nombre de la base de datos */
  dbName: string;
  /** Índices a crear al iniciar la aplicación */
  defaultIndexes: DefaultIndex[];
}

/**
 * Definición de un índice de MongoDB.
 */
export interface DefaultIndex {
  collection: string;
  indexes: Array<{
    keys: Record<string, 1 | -1 | 'text'>;
    options?: { unique?: boolean; sparse?: boolean; name?: string };
  }>;
}

/**
 * Índices por defecto registrados al arrancar la aplicación.
 * Añadir aquí cualquier nuevo índice que se necesite.
 */
export const DEFAULT_INDEXES: DefaultIndex[] = [
  {
    collection: 'users',
    indexes: [
      { keys: { email: 1 }, options: { unique: true, name: 'idx_users_email_unique' } },
      { keys: { createdAt: -1 }, options: { name: 'idx_users_createdAt' } },
    ],
  },
  {
    collection: 'plants',
    indexes: [
      { keys: { userId: 1 }, options: { name: 'idx_plants_userId' } },
      { keys: { userId: 1, createdAt: -1 }, options: { name: 'idx_plants_userId_createdAt' } },
    ],
  },
  {
    collection: 'reminders',
    indexes: [
      { keys: { plantId: 1 }, options: { name: 'idx_reminders_plantId' } },
      { keys: { userId: 1, nextDue: 1 }, options: { name: 'idx_reminders_userId_nextDue' } },
      { keys: { status: 1 }, options: { name: 'idx_reminders_status' } },
    ],
  },
  {
    collection: 'reminder_history',
    indexes: [
      { keys: { reminderId: 1, completedAt: -1 }, options: { name: 'idx_rhistory_reminderId' } },
      // TFG: índice de idempotencia para evitar procesamiento duplicado en el cron
      { keys: { idempotencyKey: 1 }, options: { unique: true, sparse: true, name: 'idx_rhistory_idempotency' } },
    ],
  },
  {
    collection: 'posts',
    indexes: [
      { keys: { authorId: 1 }, options: { name: 'idx_posts_authorId' } },
      { keys: { createdAt: -1 }, options: { name: 'idx_posts_createdAt' } },
    ],
  },
  {
    collection: 'comments',
    indexes: [
      { keys: { postId: 1, createdAt: 1 }, options: { name: 'idx_comments_postId' } },
    ],
  },
  {
    collection: 'conversations',
    indexes: [
      { keys: { participants: 1 }, options: { name: 'idx_conversations_participants' } },
      { keys: { updatedAt: -1 }, options: { name: 'idx_conversations_updatedAt' } },
    ],
  },
  {
    collection: 'messages',
    indexes: [
      { keys: { conversationId: 1, createdAt: 1 }, options: { name: 'idx_messages_conversationId' } },
      { keys: { tempId: 1 }, options: { sparse: true, name: 'idx_messages_tempId' } },
    ],
  },
  {
    collection: 'weather_cache',
    indexes: [
      { keys: { locationKey: 1 }, options: { unique: true, name: 'idx_weather_locationKey' } },
      { keys: { expiresAt: 1 }, options: { name: 'idx_weather_expiresAt' } },
    ],
  },
  {
    collection: 'post_likes',
    indexes: [
      { keys: { postId: 1, userId: 1 }, options: { unique: true, name: 'idx_post_likes_unique' } },
      { keys: { userId: 1, createdAt: -1 }, options: { name: 'idx_post_likes_userId' } },
    ],
  },
];

/**
 * Configuración de la base de datos cargada desde variables de entorno.
 */
export const databaseConfig: DatabaseConfig = {
  uri: process.env.MONGODB_URI ?? 'mongodb://localhost:27017/plants',
  dbName: process.env.MONGODB_URI?.split('/').pop()?.split('?')[0] ?? 'plants',
  defaultIndexes: DEFAULT_INDEXES,
};

// TFG: para habilitar transacciones MongoDB localmente, añadir ?replicaSet=rs0 en MONGODB_URI
// y ejecutar: mongod --replSet rs0 --bind_ip localhost
// Luego: rs.initiate() en mongosh.
// Sin replica set, las sesiones de clientSession no soportan transacciones ACID.

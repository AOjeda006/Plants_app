/**
 * @file cloudinary.config.ts
 * @description Configuración de Cloudinary para almacenamiento de imágenes.
 * @module Core
 * @layer Core
 */

import 'dotenv/config';

/**
 * Parsea la CLOUDINARY_URL en sus componentes individuales.
 * Formato: cloudinary://api_key:api_secret@cloud_name
 *
 * @returns Objeto con cloud_name, api_key, api_secret
 */
function parseCloudinaryUrl(): { cloudName: string; apiKey: string; apiSecret: string } {
  const url = process.env.CLOUDINARY_URL ?? '';
  const match = url.match(/^cloudinary:\/\/(\w+):([^@]+)@(.+)$/);
  if (!match) {
    return { cloudName: '', apiKey: '', apiSecret: '' };
  }
  return { apiKey: match[1], apiSecret: match[2], cloudName: match[3] };
}

const parsed = parseCloudinaryUrl();

/**
 * Configuración de Cloudinary cargada desde variables de entorno.
 */
export const cloudinaryConfig = {
  CLOUDINARY_CLOUD_NAME: parsed.cloudName,
  CLOUDINARY_API_KEY:    parsed.apiKey,
  CLOUDINARY_API_SECRET: parsed.apiSecret,

  /** Carpeta raíz donde se suben las imágenes en Cloudinary */
  UPLOAD_FOLDER: 'tfg_plants',
} as const;

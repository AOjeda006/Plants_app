/**
 * @file spain-locations.ts
 * @description Lista estática de las 52 capitales de provincia de España.
 * Incluye nombre corto, nombre completo, latitud y longitud.
 * Sirve como catálogo de ubicaciones para el selector de perfil de usuario.
 * @module User
 * @layer Data
 */

export interface SpainLocation {
  /** Nombre corto de la ciudad (ej. "Sevilla") */
  name:     string;
  /** Nombre completo para mostrar y guardar en User.location (ej. "Sevilla, España") */
  fullName: string;
  /** Latitud geográfica */
  lat:      number;
  /** Longitud geográfica */
  lon:      number;
}

/**
 * Las 52 capitales de provincia españolas (50 provincias + Ceuta + Melilla).
 * Coordenadas tomadas del centro urbano de cada capital.
 */
export const SPAIN_LOCATIONS: SpainLocation[] = [
  { name: 'A Coruña',                  fullName: 'A Coruña, España',                  lat: 43.3702,  lon: -8.3960  },
  { name: 'Albacete',                  fullName: 'Albacete, España',                  lat: 38.9975,  lon: -1.8565  },
  { name: 'Alicante',                  fullName: 'Alicante, España',                  lat: 38.3453,  lon: -0.4831  },
  { name: 'Almería',                   fullName: 'Almería, España',                   lat: 36.8401,  lon: -2.4669  },
  { name: 'Ávila',                     fullName: 'Ávila, España',                     lat: 40.6567,  lon: -4.6817  },
  { name: 'Badajoz',                   fullName: 'Badajoz, España',                   lat: 38.8794,  lon: -6.9706  },
  { name: 'Barcelona',                 fullName: 'Barcelona, España',                 lat: 41.3888,  lon:  2.1590  },
  { name: 'Bilbao',                    fullName: 'Bilbao, España',                    lat: 43.2627,  lon: -2.9253  },
  { name: 'Burgos',                    fullName: 'Burgos, España',                    lat: 42.3431,  lon: -3.6966  },
  { name: 'Cáceres',                   fullName: 'Cáceres, España',                   lat: 39.4753,  lon: -6.3723  },
  { name: 'Cádiz',                     fullName: 'Cádiz, España',                     lat: 36.5271,  lon: -6.2886  },
  { name: 'Castellón de la Plana',     fullName: 'Castellón de la Plana, España',     lat: 39.9864,  lon: -0.0513  },
  { name: 'Ceuta',                     fullName: 'Ceuta, España',                     lat: 35.8894,  lon: -5.3213  },
  { name: 'Ciudad Real',               fullName: 'Ciudad Real, España',               lat: 38.9860,  lon: -3.9271  },
  { name: 'Córdoba',                   fullName: 'Córdoba, España',                   lat: 37.8847,  lon: -4.7792  },
  { name: 'Cuenca',                    fullName: 'Cuenca, España',                    lat: 40.0704,  lon: -2.1374  },
  { name: 'Girona',                    fullName: 'Girona, España',                    lat: 41.9794,  lon:  2.8214  },
  { name: 'Granada',                   fullName: 'Granada, España',                   lat: 37.1773,  lon: -3.5986  },
  { name: 'Guadalajara',               fullName: 'Guadalajara, España',               lat: 40.6319,  lon: -3.1624  },
  { name: 'Huelva',                    fullName: 'Huelva, España',                    lat: 37.2614,  lon: -6.9447  },
  { name: 'Huesca',                    fullName: 'Huesca, España',                    lat: 42.1401,  lon: -0.4089  },
  { name: 'Jaén',                      fullName: 'Jaén, España',                      lat: 37.7796,  lon: -3.7849  },
  { name: 'Las Palmas de Gran Canaria', fullName: 'Las Palmas de Gran Canaria, España', lat: 28.1235, lon: -15.4366 },
  { name: 'León',                      fullName: 'León, España',                      lat: 42.5987,  lon: -5.5671  },
  { name: 'Lleida',                    fullName: 'Lleida, España',                    lat: 41.6176,  lon:  0.6200  },
  { name: 'Logroño',                   fullName: 'Logroño, España',                   lat: 42.4650,  lon: -2.4490  },
  { name: 'Lugo',                      fullName: 'Lugo, España',                      lat: 43.0097,  lon: -7.5568  },
  { name: 'Madrid',                    fullName: 'Madrid, España',                    lat: 40.4165,  lon: -3.7026  },
  { name: 'Málaga',                    fullName: 'Málaga, España',                    lat: 36.7213,  lon: -4.4215  },
  { name: 'Melilla',                   fullName: 'Melilla, España',                   lat: 35.2923,  lon: -2.9381  },
  { name: 'Murcia',                    fullName: 'Murcia, España',                    lat: 37.9834,  lon: -1.1299  },
  { name: 'Ourense',                   fullName: 'Ourense, España',                   lat: 42.3365,  lon: -7.8636  },
  { name: 'Oviedo',                    fullName: 'Oviedo, España',                    lat: 43.3619,  lon: -5.8494  },
  { name: 'Palencia',                  fullName: 'Palencia, España',                  lat: 42.0096,  lon: -4.5288  },
  { name: 'Palma',                     fullName: 'Palma, España',                     lat: 39.5696,  lon:  2.6502  },
  { name: 'Pamplona',                  fullName: 'Pamplona, España',                  lat: 42.8169,  lon: -1.6432  },
  { name: 'Pontevedra',                fullName: 'Pontevedra, España',                lat: 42.4339,  lon: -8.6475  },
  { name: 'Salamanca',                 fullName: 'Salamanca, España',                 lat: 40.9701,  lon: -5.6635  },
  { name: 'San Sebastián',             fullName: 'San Sebastián, España',             lat: 43.3168,  lon: -1.9814  },
  { name: 'Santa Cruz de Tenerife',    fullName: 'Santa Cruz de Tenerife, España',    lat: 28.4636,  lon: -16.2518 },
  { name: 'Santander',                 fullName: 'Santander, España',                 lat: 43.4635,  lon: -3.8002  },
  { name: 'Segovia',                   fullName: 'Segovia, España',                   lat: 40.9429,  lon: -4.1088  },
  { name: 'Sevilla',                   fullName: 'Sevilla, España',                   lat: 37.3891,  lon: -5.9845  },
  { name: 'Soria',                     fullName: 'Soria, España',                     lat: 41.7640,  lon: -2.4651  },
  { name: 'Tarragona',                 fullName: 'Tarragona, España',                 lat: 41.1189,  lon:  1.2445  },
  { name: 'Teruel',                    fullName: 'Teruel, España',                    lat: 40.3456,  lon: -1.1065  },
  { name: 'Toledo',                    fullName: 'Toledo, España',                    lat: 39.8567,  lon: -4.0247  },
  { name: 'Valencia',                  fullName: 'Valencia, España',                  lat: 39.4699,  lon: -0.3763  },
  { name: 'Valladolid',                fullName: 'Valladolid, España',                lat: 41.6523,  lon: -4.7245  },
  { name: 'Vitoria-Gasteiz',           fullName: 'Vitoria-Gasteiz, España',           lat: 42.8467,  lon: -2.6727  },
  { name: 'Zamora',                    fullName: 'Zamora, España',                    lat: 41.5036,  lon: -5.7447  },
  { name: 'Zaragoza',                  fullName: 'Zaragoza, España',                  lat: 41.6488,  lon: -0.8890  },
];

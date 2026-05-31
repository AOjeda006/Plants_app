/**
 * @file User.ts
 * @description Entidad de dominio que representa un usuario de la aplicación.
 * Contiene únicamente lógica de negocio pura, sin dependencias de framework ni de BD.
 * @module Auth
 * @layer Domain
 */

/**
 * Roles disponibles en el sistema.
 * - user: usuario estándar.
 * - admin: acceso a operaciones de administración (aprobar especies, gestionar usuarios, etc.).
 */
export type UserRole = 'user' | 'admin';

/**
 * Preferencias configurables por el usuario.
 */
export interface UserPreferences {
  /** Aparecer en búsquedas de chat de otros usuarios */
  appearInChatSearch: boolean;
  /** Considerar el clima al calcular recordatorios de riego por defecto */
  considerWeatherByDefault: boolean;
  /** Si true, el perfil del usuario no aparece en el feed público ni acepta nuevas conversaciones */
  isPrivate: boolean;
  /**
   * Si false, el backend NO envía push FCM al dispositivo aunque tenga
   * fcmToken registrado. Capas 1 (in-app) y 2 (socket) siguen activas
   * — el toggle SOLO afecta a la capa 3 (push del sistema).
   * Default: true (si la propiedad está ausente, el backend asume
   * habilitado para mantener compatibilidad con perfiles legacy).
   */
  pushNotifications?: boolean;
}

/**
 * Entidad de dominio User.
 * Representa el estado válido de un usuario dentro del sistema.
 * Los mappers se encargan de convertir entre esta entidad y los documentos de MongoDB.
 */
export class User {
  /** Identificador único (ObjectId de MongoDB serializado como string) */
  readonly id: string;

  /** Rol del usuario en el sistema (user | admin) */
  readonly role: UserRole;

  /** Nombre completo del usuario */
  readonly name: string;

  /** Email único del usuario */
  readonly email: string;

  /** Hash bcrypt de la contraseña. Nunca debe exponerse al cliente */
  readonly passwordHash: string;

  /** URL de la foto de perfil (Cloudinary) */
  readonly photo?: string;

  /** URL de la imagen de banner/fondo de perfil (Cloudinary) */
  readonly bannerPhoto?: string;

  /** Biografía opcional del usuario */
  readonly bio?: string;

  /** Ubicación opcional para cálculos meteorológicos (nombre: ej. "Sevilla, España") */
  readonly location?: string;

  /** Latitud geográfica de la ubicación del usuario (de las capitales de provincia) */
  readonly locationLat?: number;

  /** Longitud geográfica de la ubicación del usuario (de las capitales de provincia) */
  readonly locationLon?: number;

  /** Token FCM para notificaciones push. Nunca debe exponerse al cliente */
  readonly fcmToken?: string;

  /**
   * Último título de push de chat enviado al usuario mientras estaba
   * offline. Se usa para deduplicar pushes consecutivos: si el cron
   * `_pushIfReceiverOffline` calcula un título igual al guardado,
   * omite el envío (evita spam de vibraciones cuando llegan varios
   * mensajes seguidos del mismo sender o mientras la "Varios usuarios"
   * sigue siendo la respuesta correcta). Se resetea a null en
   * `SocketGateway.handleConnection` cuando el usuario abre la app
   * (señal "ya está activo, puedes mandar la próxima push si vuelve a
   * cerrarse").
   */
  readonly lastChatPushTitle?: string | null;

  /** Preferencias de notificación y comportamiento */
  readonly preferences: UserPreferences;

  /** Fecha de creación de la cuenta */
  readonly createdAt: Date;

  /** Fecha de la última modificación */
  readonly updatedAt: Date;

  /** Fecha de borrado lógico. Si está definida, el usuario está inactivo */
  readonly deletedAt?: Date;

  /** Fecha hasta la que el usuario está baneado. Si bannedUntil > now, no puede publicar/comentar/dar like */
  readonly bannedUntil?: Date;

  constructor(params: {
    id: string;
    role?: UserRole;
    name: string;
    email: string;
    passwordHash: string;
    photo?: string;
    bannerPhoto?: string;
    bio?: string;
    location?: string;
    locationLat?: number;
    locationLon?: number;
    fcmToken?: string;
    lastChatPushTitle?: string | null;
    preferences?: Partial<UserPreferences>;
    createdAt: Date;
    updatedAt: Date;
    deletedAt?: Date;
    bannedUntil?: Date;
  }) {
    this.id           = params.id;
    this.role         = params.role ?? 'user';
    this.name         = params.name;
    this.email        = params.email;
    this.passwordHash = params.passwordHash;
    this.photo        = params.photo;
    this.bannerPhoto  = params.bannerPhoto;
    this.bio          = params.bio;
    this.location     = params.location;
    this.locationLat  = params.locationLat;
    this.locationLon  = params.locationLon;
    this.fcmToken          = params.fcmToken;
    this.lastChatPushTitle = params.lastChatPushTitle;
    this.createdAt    = params.createdAt;
    this.updatedAt    = params.updatedAt;
    this.deletedAt    = params.deletedAt;
    this.bannedUntil  = params.bannedUntil;

    // Preferencias con valores por defecto seguros
    this.preferences = {
      appearInChatSearch:        params.preferences?.appearInChatSearch        ?? true,
      considerWeatherByDefault:  params.preferences?.considerWeatherByDefault  ?? false,
      isPrivate:                 params.preferences?.isPrivate                 ?? false,
      // Opcional, default true. Preserva undefined si no llega explícitamente
      // (canReceiveNotifications usa `!== false`).
      pushNotifications:         params.preferences?.pushNotifications,
    };
  }

  /**
   * Devuelve una copia del usuario sin campos sensibles (passwordHash, fcmToken).
   * Usar siempre al devolver datos de usuario al cliente.
   *
   * @returns Objeto plano seguro para serializar en la respuesta HTTP.
   */
  sanitizeForPublic(): Omit<User, 'passwordHash' | 'fcmToken'> {
    const { passwordHash: _pw, fcmToken: _fcm, ...publicFields } = this;
    return publicFields as Omit<User, 'passwordHash' | 'fcmToken'>;
  }

  /**
   * Indica si el usuario puede recibir notificaciones push.
   * Requiere FCM token registrado Y que la preferencia
   * `pushNotifications` no esté desactivada explícitamente.
   *
   * El operador `!== false` mantiene compatibilidad con perfiles legacy:
   * si `preferences.pushNotifications` es `undefined`, se asume `true`
   * por defecto.
   *
   * @returns true si tiene fcmToken Y pushNotifications no es false.
   */
  canReceiveNotifications(): boolean {
    return Boolean(this.fcmToken) &&
           this.preferences?.pushNotifications !== false;
  }
}

/**
 * @file policyMatrix.ts
 * @description Matriz de permisos del sistema.
 * Define qué acciones puede realizar cada rol sobre cada recurso.
 * Uso: hasPermission(role, action, resource) → boolean
 * @module Core
 * @layer Core
 */

import type { UserRole } from '../../domain/entities/User.js';

// ─── Tipos de acción ─────────────────────────────────────────────────────────

/**
 * Acciones posibles sobre recursos del sistema.
 * Se amplía a medida que se añaden módulos.
 */
export type PolicyAction =
  | 'manage_users'        // Gestión administrativa de usuarios
  | 'view_admin_reports'  // Ver informes del panel de admin
  | 'restore_deleted'     // Restaurar elementos eliminados lógicamente
  | 'trigger_reminders'   // Forzar la ejecución del cron de recordatorios
  | 'read'                // Lectura genérica
  | 'write'               // Escritura genérica (propio recurso)
  | 'delete';             // Borrado genérico (propio recurso)

// ─── Tipos de recurso ────────────────────────────────────────────────────────

/**
 * Recursos del sistema sobre los que se aplican permisos.
 */
export type PolicyResource =
  | 'species'
  | 'users'
  | 'plants'
  | 'reminders'
  | 'posts'
  | 'comments'
  | 'messages';

// ─── Matriz de permisos ──────────────────────────────────────────────────────

/**
 * Matriz de permisos: PolicyMatrix[role][resource] = Set<action>
 * Define de forma declarativa qué puede hacer cada rol.
 */
type PolicyMatrix = Record<UserRole, Partial<Record<PolicyResource, PolicyAction[]>>>;

const POLICY_MATRIX: PolicyMatrix = {
  user: {
    species:   ['read'],
    plants:    ['read', 'write', 'delete'],
    reminders: ['read', 'write', 'delete'],
    posts:     ['read', 'write', 'delete'],
    comments:  ['read', 'write', 'delete'],
    messages:  ['read', 'write'],
  },
  admin: {
    species:   ['read'],
    plants:    ['read', 'write', 'delete'],
    reminders: ['read', 'write', 'delete', 'trigger_reminders'],
    posts:     ['read', 'write', 'delete'],
    comments:  ['read', 'write', 'delete'],
    messages:  ['read', 'write'],
    users:     ['read', 'manage_users', 'restore_deleted', 'view_admin_reports'],
  },
};

// ─── Función pública ─────────────────────────────────────────────────────────

/**
 * Verifica si un rol tiene permiso para realizar una acción sobre un recurso.
 *
 * @param role — Rol del usuario ('user' | 'admin').
 * @param action — Acción a realizar (ej: 'approve_species').
 * @param resource — Recurso sobre el que se actúa (ej: 'species').
 * @returns true si el rol está autorizado; false en cualquier otro caso.
 */
export function hasPermission(
  role: UserRole | undefined,
  action: PolicyAction,
  resource: PolicyResource,
): boolean {
  if (!role) return false;
  const allowed = POLICY_MATRIX[role]?.[resource] ?? [];
  return allowed.includes(action);
}

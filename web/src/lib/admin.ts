export type AdminRole = 'super_admin' | 'admin' | 'superviseur'

export type Admin = {
  id: string
  email: string
  full_name: string
  role: AdminRole
  is_active: boolean
  last_login: string | null
  created_at: string
}

// Permissions par rôle
export const PERMISSIONS: Record<AdminRole, string[]> = {
  super_admin: [
    'manage_admins',
    'manage_services',
    'manage_missions',
    'manage_users',
    'suspend_client',
    'suspend_agent',
    'suspend_account',
    'view_stats',
    'view_logs',
  ],
  admin: [
    'manage_services',
    'manage_missions',
    'manage_users',
    'suspend_client',
    'suspend_agent',
    'suspend_account',
    'view_stats',
    'view_logs',
  ],
  superviseur: [
    'manage_missions',
    'manage_users',
    'suspend_client',
    'suspend_agent',
    'view_stats',
  ],
}

export function hasPermission(role: AdminRole, permission: string): boolean {
  return PERMISSIONS[role]?.includes(permission) ?? false
}

export function getRoleLabel(role: AdminRole): string {
  switch (role) {
    case 'super_admin': return 'Super Admin'
    case 'admin': return 'Admin'
    case 'superviseur': return 'Superviseur'
  }
}

export function getRoleColor(role: AdminRole): string {
  switch (role) {
    case 'super_admin': return 'bg-red-100 text-red-800'
    case 'admin': return 'bg-blue-100 text-blue-800'
    case 'superviseur': return 'bg-green-100 text-green-800'
  }
}

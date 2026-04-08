'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { useEffect, useState } from 'react'
import { LayoutDashboard, Package, ClipboardList, Users, BarChart3, LogOut, Shield, ScrollText } from 'lucide-react'
import { type Admin, type AdminRole, hasPermission, getRoleLabel, getRoleColor } from '@/lib/admin'

const allNavItems = [
  { href: '/dashboard', label: 'Tableau de bord', icon: LayoutDashboard, permission: null },
  { href: '/dashboard/services', label: 'Services', icon: Package, permission: 'manage_services' },
  { href: '/dashboard/missions', label: 'Missions', icon: ClipboardList, permission: 'manage_missions' },
  { href: '/dashboard/users', label: 'Utilisateurs', icon: Users, permission: 'manage_users' },
  { href: '/dashboard/admins', label: 'Administrateurs', icon: Shield, permission: 'manage_admins' },
  { href: '/dashboard/logs', label: 'Journal', icon: ScrollText, permission: 'view_logs' },
  { href: '/dashboard/stats', label: 'Statistiques', icon: BarChart3, permission: 'view_stats' },
]

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const router = useRouter()
  const [admin, setAdmin] = useState<Admin | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/auth')
      .then(r => r.json())
      .then(data => {
        if (data.admin) {
          setAdmin(data.admin)
        } else {
          router.push('/')
        }
        setLoading(false)
      })
      .catch(() => {
        router.push('/')
        setLoading(false)
      })
  }, [router])

  async function handleLogout() {
    await fetch('/api/auth', { method: 'DELETE' })
    router.push('/')
  }

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center text-gray-400">Chargement...</div>
  }

  if (!admin) return null

  const navItems = allNavItems.filter(
    item => item.permission === null || hasPermission(admin.role as AdminRole, item.permission)
  )

  return (
    <div className="flex min-h-screen">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-6 border-b border-gray-200">
          <h1 className="text-lg font-bold" style={{ color: '#00A8E8' }}>Cartel Conciergeries</h1>
          <p className="text-xs text-gray-400 mt-1">Administration</p>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const isActive = pathname === item.href ||
              (item.href !== '/dashboard' && pathname.startsWith(item.href))
            const Icon = item.icon
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition ${
                  isActive
                    ? 'text-white'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
                style={isActive ? { backgroundColor: '#00A8E8' } : undefined}
              >
                <Icon size={18} />
                {item.label}
              </Link>
            )
          })}
        </nav>

        {/* Profil admin */}
        <div className="p-4 border-t border-gray-200">
          <div className="px-4 py-2 mb-2">
            <p className="text-sm font-medium truncate">{admin.full_name}</p>
            <p className="text-xs text-gray-400 truncate">{admin.email}</p>
            <span className={`inline-block mt-1 text-xs px-2 py-0.5 rounded-lg font-medium ${getRoleColor(admin.role as AdminRole)}`}>
              {getRoleLabel(admin.role as AdminRole)}
            </span>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-red-500 hover:bg-red-50 w-full transition cursor-pointer"
          >
            <LogOut size={18} />
            Déconnexion
          </button>
        </div>
      </aside>

      {/* Content */}
      <main className="flex-1 p-8 overflow-auto">
        {children}
      </main>
    </div>
  )
}

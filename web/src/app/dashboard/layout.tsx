'use client'

import Link from 'next/link'
import Image from 'next/image'
import { usePathname, useRouter } from 'next/navigation'
import { useEffect, useState, useCallback } from 'react'
import {
  LayoutDashboard, Package, ClipboardList, Users, BarChart3,
  LogOut, Shield, ScrollText, Menu, X, Moon, Sun, User, Bell, Settings,
} from 'lucide-react'
import { type Admin, type AdminRole, hasPermission, getRoleLabel, getRoleColor } from '@/lib/admin'
import { getSupabase } from '@/lib/supabase'

const allNavItems = [
  { href: '/dashboard', label: 'Tableau de bord', icon: LayoutDashboard, permission: null },
  { href: '/dashboard/services', label: 'Services', icon: Package, permission: 'manage_services' },
  { href: '/dashboard/missions', label: 'Missions', icon: ClipboardList, permission: 'manage_missions' },
  { href: '/dashboard/users', label: 'Utilisateurs', icon: Users, permission: 'manage_users' },
  { href: '/dashboard/admins', label: 'Administrateurs', icon: Shield, permission: 'manage_admins' },
  { href: '/dashboard/settings', label: 'Paramètres', icon: Settings, permission: 'manage_services' },
  { href: '/dashboard/logs', label: 'Journal', icon: ScrollText, permission: 'view_logs' },
  { href: '/dashboard/stats', label: 'Statistiques', icon: BarChart3, permission: 'view_stats' },
]

const SESSION_TIMEOUT = 8 * 60 * 60 * 1000 // 8 heures

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  const router = useRouter()
  const [admin, setAdmin] = useState<Admin | null>(null)
  const [loading, setLoading] = useState(true)
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [darkMode, setDarkMode] = useState(false)
  const [pendingCount, setPendingCount] = useState(0)

  const handleLogout = useCallback(() => {
    localStorage.removeItem('admin_session')
    localStorage.removeItem('admin_session_time')
    window.location.href = '/'
  }, [])

  // Session + admin check
  useEffect(() => {
    const session = localStorage.getItem('admin_session')
    const sessionTime = localStorage.getItem('admin_session_time')

    if (!session) {
      router.push('/')
      return
    }

    // Vérifier expiration
    if (sessionTime && Date.now() - parseInt(sessionTime) > SESSION_TIMEOUT) {
      handleLogout()
      return
    }

    try {
      setAdmin(JSON.parse(session))
    } catch {
      handleLogout()
      return
    }

    // Dark mode
    const dm = localStorage.getItem('dark_mode')
    if (dm === 'true') setDarkMode(true)

    setLoading(false)
  }, [router, handleLogout])

  // Refresh session time on activity
  useEffect(() => {
    function refreshSession() {
      if (localStorage.getItem('admin_session')) {
        localStorage.setItem('admin_session_time', String(Date.now()))
      }
    }
    window.addEventListener('click', refreshSession)
    window.addEventListener('keydown', refreshSession)
    return () => {
      window.removeEventListener('click', refreshSession)
      window.removeEventListener('keydown', refreshSession)
    }
  }, [])

  // Auto-check session expiration
  useEffect(() => {
    const interval = setInterval(() => {
      const sessionTime = localStorage.getItem('admin_session_time')
      if (sessionTime && Date.now() - parseInt(sessionTime) > SESSION_TIMEOUT) {
        handleLogout()
      }
    }, 60000)
    return () => clearInterval(interval)
  }, [handleLogout])

  // Pending missions count (badge)
  useEffect(() => {
    async function loadPending() {
      try {
        const { count } = await getSupabase()
          .from('missions')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'pending')
        setPendingCount(count || 0)
      } catch { /* ignore */ }
    }
    loadPending()
    const interval = setInterval(loadPending, 30000)
    return () => clearInterval(interval)
  }, [])

  // Realtime missions
  useEffect(() => {
    const channel = getSupabase()
      .channel('missions-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'missions' }, () => {
        getSupabase()
          .from('missions')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'pending')
          .then(({ count }) => setPendingCount(count || 0))
      })
      .subscribe()

    return () => { getSupabase().removeChannel(channel) }
  }, [])

  function toggleDarkMode() {
    const newVal = !darkMode
    setDarkMode(newVal)
    localStorage.setItem('dark_mode', String(newVal))
  }

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center text-gray-400">Chargement...</div>
  }
  if (!admin) return null

  const navItems = allNavItems.filter(
    item => item.permission === null || hasPermission(admin.role as AdminRole, item.permission)
  )

  const bg = darkMode ? 'bg-gray-900' : 'bg-[#f5f7fa]'
  const sidebarBg = darkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'
  const textColor = darkMode ? 'text-gray-100' : 'text-gray-900'
  const subtextColor = darkMode ? 'text-gray-400' : 'text-gray-500'
  const navInactive = darkMode ? 'text-gray-300 hover:bg-gray-700' : 'text-gray-600 hover:bg-gray-100'

  return (
    <div className={`flex min-h-screen ${bg} ${textColor}`}>
      {/* Overlay mobile */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`fixed lg:static inset-y-0 left-0 z-50 w-64 ${sidebarBg} border-r flex flex-col transform transition-transform lg:transform-none ${
        sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
      }`}>
        <div className={`p-4 border-b ${darkMode ? 'border-gray-700' : 'border-gray-200'}`}>
          <div className="flex items-center gap-3">
            <Image src="/logo.png" alt="Logo" width={40} height={40} className="rounded-lg" />
            <div>
              <h1 className="text-sm font-bold" style={{ color: '#00A8E8' }}>Cartel Conciergeries</h1>
              <p className={`text-xs ${subtextColor}`}>Administration</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 p-3 space-y-1 overflow-auto">
          {navItems.map((item) => {
            const isActive = pathname === item.href ||
              (item.href !== '/dashboard' && pathname.startsWith(item.href))
            const Icon = item.icon
            const showBadge = item.href === '/dashboard/missions' && pendingCount > 0
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setSidebarOpen(false)}
                className={`flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition ${
                  isActive ? 'text-white' : navInactive
                }`}
                style={isActive ? { backgroundColor: '#00A8E8' } : undefined}
              >
                <Icon size={18} />
                <span className="flex-1">{item.label}</span>
                {showBadge && (
                  <span className="bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-bold">
                    {pendingCount}
                  </span>
                )}
              </Link>
            )
          })}
        </nav>

        {/* Footer sidebar */}
        <div className={`p-3 border-t ${darkMode ? 'border-gray-700' : 'border-gray-200'}`}>
          {/* Profile link */}
          <Link
            href="/dashboard/profile"
            onClick={() => setSidebarOpen(false)}
            className={`flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition ${
              pathname === '/dashboard/profile' ? 'text-white' : navInactive
            }`}
            style={pathname === '/dashboard/profile' ? { backgroundColor: '#00A8E8' } : undefined}
          >
            <User size={18} />
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{admin.full_name}</p>
              <span className={`text-xs ${getRoleColor(admin.role as AdminRole)} px-1.5 py-0.5 rounded`}>
                {getRoleLabel(admin.role as AdminRole)}
              </span>
            </div>
          </Link>

          <div className="flex items-center gap-1 mt-2 px-2">
            <button
              onClick={toggleDarkMode}
              className={`p-2 rounded-lg transition cursor-pointer ${darkMode ? 'hover:bg-gray-700' : 'hover:bg-gray-100'}`}
              title={darkMode ? 'Mode clair' : 'Mode sombre'}
            >
              {darkMode ? <Sun size={16} className="text-yellow-400" /> : <Moon size={16} className="text-gray-400" />}
            </button>
            <button
              onClick={handleLogout}
              className="p-2 rounded-lg hover:bg-red-50 transition cursor-pointer flex-1 flex items-center gap-2 text-red-500 text-sm"
            >
              <LogOut size={16} />
              <span className="text-xs">Déconnexion</span>
            </button>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top bar mobile */}
        <header className={`lg:hidden flex items-center justify-between p-4 ${sidebarBg} border-b ${darkMode ? 'border-gray-700' : 'border-gray-200'}`}>
          <button onClick={() => setSidebarOpen(true)} className="cursor-pointer p-1">
            <Menu size={24} />
          </button>
          <div className="flex items-center gap-2">
            <Image src="/logo.png" alt="Logo" width={28} height={28} className="rounded" />
            <span className="text-sm font-bold" style={{ color: '#00A8E8' }}>Cartel</span>
          </div>
          <div className="flex items-center gap-2">
            {pendingCount > 0 && (
              <Link href="/dashboard/missions" className="relative">
                <Bell size={20} />
                <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-4 h-4 flex items-center justify-center text-[10px]">
                  {pendingCount}
                </span>
              </Link>
            )}
          </div>
        </header>

        <main className={`flex-1 p-4 md:p-8 overflow-auto ${darkMode ? 'bg-gray-900' : ''}`}>
          {children}
        </main>
      </div>
    </div>
  )
}

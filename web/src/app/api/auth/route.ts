import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export const runtime = 'edge'

export async function POST(request: Request) {
  const { email, password } = await request.json()

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

  if (!supabaseUrl || !supabaseKey) {
    return NextResponse.json({ error: 'Config error' }, { status: 500 })
  }

  // Vérifier le mot de passe via pgcrypto dans Supabase
  const res = await fetch(`${supabaseUrl}/rest/v1/rpc/admin_login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': supabaseKey,
      'Authorization': `Bearer ${supabaseKey}`,
    },
    body: JSON.stringify({ p_email: email, p_password: password }),
  })

  const data = await res.json()

  if (!res.ok || !data || data.length === 0) {
    return NextResponse.json({ error: 'Email ou mot de passe incorrect' }, { status: 401 })
  }

  const admin = Array.isArray(data) ? data[0] : data

  // Stocker la session
  const session = JSON.stringify({
    id: admin.id,
    email: admin.email,
    full_name: admin.full_name,
    role: admin.role,
  })

  const cookieStore = await cookies()
  cookieStore.set('admin_session', session, {
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
    maxAge: 60 * 60 * 24,
    path: '/',
  })

  return NextResponse.json({ ok: true, admin: { full_name: admin.full_name, role: admin.role } })
}

export async function GET() {
  const cookieStore = await cookies()
  const session = cookieStore.get('admin_session')

  if (!session) {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
  }

  try {
    const admin = JSON.parse(session.value)
    return NextResponse.json({ admin })
  } catch {
    return NextResponse.json({ error: 'Invalid session' }, { status: 401 })
  }
}

export async function DELETE() {
  const cookieStore = await cookies()
  cookieStore.delete('admin_session')
  return NextResponse.json({ ok: true })
}

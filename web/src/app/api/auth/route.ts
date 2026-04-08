import { NextResponse } from 'next/server'

export const runtime = 'edge'

export async function POST(request: Request) {
  const { email, password } = await request.json()

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://yetjlxvmnzmqdbjcrdew.supabase.co'
  const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlldGpseHZtbnptcWRiamNyZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTc2MDMsImV4cCI6MjA5MTIzMzYwM30.gL2Fin4havOPgZ39celz_vQJ5gwHULgRcR4bEBOSeuE'

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

  if (!res.ok || !data || (Array.isArray(data) && data.length === 0)) {
    return NextResponse.json({ error: 'Email ou mot de passe incorrect' }, { status: 401 })
  }

  const admin = Array.isArray(data) ? data[0] : data

  return NextResponse.json({
    ok: true,
    admin: {
      id: admin.id,
      email: admin.email,
      full_name: admin.full_name,
      role: admin.role,
    },
  })
}

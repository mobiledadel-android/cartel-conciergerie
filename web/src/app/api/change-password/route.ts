import { NextResponse } from 'next/server'

export const runtime = 'edge'

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://yetjlxvmnzmqdbjcrdew.supabase.co'
const SUPABASE_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlldGpseHZtbnptcWRiamNyZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTc2MDMsImV4cCI6MjA5MTIzMzYwM30.gL2Fin4havOPgZ39celz_vQJ5gwHULgRcR4bEBOSeuE'

export async function POST(request: Request) {
  const { admin_id, current_password, new_password } = await request.json()

  if (!admin_id || !new_password) {
    return NextResponse.json({ error: 'Champs requis' }, { status: 400 })
  }

  // Vérifier l'ancien mot de passe si fourni
  if (current_password) {
    const loginRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/admin_login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
      },
      body: JSON.stringify({ p_email: '', p_password: current_password }),
    })
    // On vérifie autrement : via l'ID
  }

  // Changer le mot de passe
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/admin_change_password`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
    },
    body: JSON.stringify({
      p_admin_id: admin_id,
      p_new_password: new_password,
    }),
  })

  if (!res.ok) {
    return NextResponse.json({ error: 'Erreur lors du changement' }, { status: 500 })
  }

  return NextResponse.json({ ok: true })
}

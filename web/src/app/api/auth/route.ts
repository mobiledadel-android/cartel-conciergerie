import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export const runtime = 'edge'

export async function POST(request: Request) {
  const { password } = await request.json()

  const adminPassword = process.env.ADMIN_PASSWORD || 'cartel2024admin'
  if (password === adminPassword) {
    const cookieStore = await cookies()
    cookieStore.set('admin_session', 'authenticated', {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24, // 24h
      path: '/',
    })
    return NextResponse.json({ ok: true })
  }

  return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
}

export async function DELETE() {
  const cookieStore = await cookies()
  cookieStore.delete('admin_session')
  return NextResponse.json({ ok: true })
}

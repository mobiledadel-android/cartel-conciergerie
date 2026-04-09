import { NextResponse } from 'next/server'
import { Resend } from 'resend'

export const runtime = 'edge'

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://yetjlxvmnzmqdbjcrdew.supabase.co'
const SUPABASE_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlldGpseHZtbnptcWRiamNyZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTc2MDMsImV4cCI6MjA5MTIzMzYwM30.gL2Fin4havOPgZ39celz_vQJ5gwHULgRcR4bEBOSeuE'

function generatePassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789'
  let password = ''
  for (let i = 0; i < 12; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return password
}

function getRoleLabel(role: string): string {
  switch (role) {
    case 'super_admin': return 'Super Administrateur'
    case 'admin': return 'Administrateur'
    case 'superviseur': return 'Superviseur'
    default: return role
  }
}

function buildEmailHtml(name: string, email: string, password: string, role: string, dashboardUrl: string): string {
  return `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#f5f7fa;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f5f7fa;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">

          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, #00A8E8 0%, #0077B6 100%);padding:32px 40px;text-align:center;">
              <table cellpadding="0" cellspacing="0" style="margin:0 auto;">
                <tr>
                  <td style="padding-right:12px;vertical-align:middle;">
                    <div style="width:48px;height:48px;background-color:rgba(255,255,255,0.2);border-radius:12px;text-align:center;line-height:48px;font-size:24px;">🏠</div>
                  </td>
                  <td style="vertical-align:middle;">
                    <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:-0.5px;">Cartel Conciergeries</h1>
                    <p style="margin:2px 0 0;color:rgba(255,255,255,0.8);font-size:12px;letter-spacing:1px;text-transform:uppercase;">Administration</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:40px;">
              <h2 style="margin:0 0 8px;color:#1a1a2e;font-size:20px;font-weight:600;">Bienvenue ${name} 👋</h2>
              <p style="margin:0 0 24px;color:#6b7280;font-size:15px;line-height:1.6;">
                Votre compte administrateur a été créé sur la plateforme <strong>Cartel Conciergeries</strong>.
                Vous avez été désigné(e) comme <strong>${getRoleLabel(role)}</strong>.
              </p>

              <!-- Credentials Card -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f0f9ff;border-radius:12px;border:1px solid #bae6fd;margin-bottom:24px;">
                <tr>
                  <td style="padding:24px;">
                    <p style="margin:0 0 16px;color:#0077B6;font-size:13px;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;">Vos identifiants de connexion</p>

                    <table cellpadding="0" cellspacing="0" width="100%">
                      <tr>
                        <td style="padding:8px 0;color:#6b7280;font-size:14px;width:120px;">Email</td>
                        <td style="padding:8px 0;color:#1a1a2e;font-size:14px;font-weight:600;">${email}</td>
                      </tr>
                      <tr>
                        <td style="padding:8px 0;color:#6b7280;font-size:14px;">Mot de passe</td>
                        <td style="padding:8px 0;">
                          <code style="background-color:#ffffff;border:1px solid #e5e7eb;border-radius:6px;padding:4px 12px;font-size:15px;font-weight:700;color:#E91E63;letter-spacing:1px;">${password}</code>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding:8px 0;color:#6b7280;font-size:14px;">Rôle</td>
                        <td style="padding:8px 0;color:#1a1a2e;font-size:14px;font-weight:600;">${getRoleLabel(role)}</td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <!-- CTA Button -->
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center" style="padding:8px 0 24px;">
                    <a href="${dashboardUrl}" style="display:inline-block;background:linear-gradient(135deg, #00A8E8 0%, #0077B6 100%);color:#ffffff;text-decoration:none;padding:14px 32px;border-radius:12px;font-size:15px;font-weight:600;letter-spacing:0.3px;">
                      Accéder au tableau de bord →
                    </a>
                  </td>
                </tr>
              </table>

              <!-- Warning -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#fef3cd;border-radius:10px;border:1px solid #ffd43b;">
                <tr>
                  <td style="padding:16px 20px;">
                    <p style="margin:0;color:#92400e;font-size:13px;line-height:1.5;">
                      ⚠️ <strong>Important :</strong> Pour des raisons de sécurité, nous vous recommandons fortement de
                      <strong>changer votre mot de passe</strong> dès votre première connexion.
                      Vous trouverez cette option dans votre profil sur le tableau de bord.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#f9fafb;padding:24px 40px;border-top:1px solid #e5e7eb;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td>
                    <p style="margin:0;color:#9ca3af;font-size:12px;">Cartel Conciergeries</p>
                    <p style="margin:4px 0 0;color:#d1d5db;font-size:11px;">Assistance · Amour · Compassion</p>
                  </td>
                  <td align="right">
                    <p style="margin:0;color:#d1d5db;font-size:11px;">Libreville, Gabon</p>
                    <p style="margin:4px 0 0;color:#d1d5db;font-size:11px;">© ${new Date().getFullYear()} Tous droits réservés</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

        </table>

        <!-- Sub-footer -->
        <p style="margin:24px 0 0;color:#9ca3af;font-size:11px;text-align:center;">
          Cet email a été envoyé automatiquement. Merci de ne pas y répondre.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>`
}

export async function POST(request: Request) {
  const { email, full_name, role, created_by, dashboard_url } = await request.json()

  if (!email || !full_name || !role) {
    return NextResponse.json({ error: 'Champs requis' }, { status: 400 })
  }

  // Générer un mot de passe
  const password = generatePassword()

  // Créer l'admin dans Supabase
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/admin_create`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`,
    },
    body: JSON.stringify({
      p_email: email,
      p_password: password,
      p_full_name: full_name,
      p_role: role,
      p_created_by: created_by || null,
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    return NextResponse.json({ error: `Erreur création: ${err}` }, { status: 500 })
  }

  // Envoyer l'email
  const resendKey = process.env.RESEND_API_KEY || 're_W1fE3CEG_CJs1a244ZUC2u4r5hLeGp9y6'
  if (resendKey) {
    try {
      const resend = new Resend(resendKey)
      await resend.emails.send({
        from: 'Cartel Conciergeries <onboarding@resend.dev>',
        to: email,
        subject: '🔑 Vos identifiants Cartel Conciergeries',
        html: buildEmailHtml(full_name, email, password, role, dashboard_url || 'https://cartel-conciergeries.pages.dev'),
      })
    } catch (e) {
      // L'email n'est pas critique, on continue
      console.error('Email error:', e)
    }
  }

  return NextResponse.json({
    ok: true,
    password, // Retourné pour affichage si l'email n'est pas envoyé
    email_sent: !!resendKey,
  })
}

-- ============================================
-- Système d'administration hiérarchisé
-- Super Admin > Admin > Superviseur
-- ============================================

CREATE TYPE admin_role AS ENUM ('super_admin', 'admin', 'superviseur');

-- Table des administrateurs (séparée des utilisateurs de l'app)
CREATE TABLE admins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role admin_role NOT NULL DEFAULT 'superviseur',
  is_active BOOLEAN DEFAULT TRUE,
  last_login TIMESTAMPTZ,
  created_by UUID REFERENCES admins(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Journal des actions admin (traçabilité)
CREATE TABLE admin_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES admins(id),
  action TEXT NOT NULL,
  target_type TEXT, -- 'profile', 'service', 'mission', 'admin'
  target_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Mise à jour profiles : suspension granulaire
ALTER TABLE profiles ADD COLUMN is_client_suspended BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN is_agent_suspended BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN suspension_reason TEXT;
ALTER TABLE profiles ADD COLUMN suspended_by UUID REFERENCES admins(id);
ALTER TABLE profiles ADD COLUMN suspended_at TIMESTAMPTZ;

-- Index
CREATE INDEX idx_admins_email ON admins(email);
CREATE INDEX idx_admin_logs_admin ON admin_logs(admin_id);
CREATE INDEX idx_admin_logs_target ON admin_logs(target_type, target_id);
CREATE INDEX idx_profiles_client_suspended ON profiles(is_client_suspended) WHERE is_client_suspended = TRUE;
CREATE INDEX idx_profiles_agent_suspended ON profiles(is_agent_suspended) WHERE is_agent_suspended = TRUE;

-- RLS
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lecture admins" ON admins FOR SELECT USING (true);
CREATE POLICY "Insertion admins" ON admins FOR INSERT WITH CHECK (true);
CREATE POLICY "Mise à jour admins" ON admins FOR UPDATE USING (true);
CREATE POLICY "Suppression admins" ON admins FOR DELETE USING (true);

CREATE POLICY "Lecture logs" ON admin_logs FOR SELECT USING (true);
CREATE POLICY "Insertion logs" ON admin_logs FOR INSERT WITH CHECK (true);

-- Trigger updated_at
CREATE TRIGGER tr_admins_updated
  BEFORE UPDATE ON admins
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- Créer le premier Super Admin
-- Mot de passe : cartel2024admin (hashé avec pgcrypto)
-- ============================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO admins (email, password_hash, full_name, role) VALUES
  ('admin@cartel.ga', crypt('cartel2024admin', gen_salt('bf')), 'Super Administrateur', 'super_admin');

-- ============================================
-- Fonction de login admin (appelée depuis le dashboard)
-- ============================================

CREATE OR REPLACE FUNCTION admin_login(p_email TEXT, p_password TEXT)
RETURNS TABLE(id UUID, email TEXT, full_name TEXT, role admin_role)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Mettre à jour last_login
  UPDATE admins SET last_login = NOW()
  WHERE admins.email = p_email
    AND admins.password_hash = crypt(p_password, admins.password_hash)
    AND admins.is_active = TRUE;

  RETURN QUERY
  SELECT a.id, a.email, a.full_name, a.role
  FROM admins a
  WHERE a.email = p_email
    AND a.password_hash = crypt(p_password, a.password_hash)
    AND a.is_active = TRUE;
END;
$$;

-- ============================================
-- Fonction pour changer le mot de passe d'un admin
-- ============================================

CREATE OR REPLACE FUNCTION admin_change_password(p_admin_id UUID, p_new_password TEXT)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE admins SET password_hash = crypt(p_new_password, gen_salt('bf'))
  WHERE id = p_admin_id;
END;
$$;

-- ============================================
-- Fonction pour créer un admin (avec hash du mdp)
-- ============================================

CREATE OR REPLACE FUNCTION admin_create(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_role admin_role,
  p_created_by UUID
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_id UUID;
BEGIN
  INSERT INTO admins (email, password_hash, full_name, role, created_by)
  VALUES (p_email, crypt(p_password, gen_salt('bf')), p_full_name, p_role, p_created_by)
  RETURNING id INTO new_id;
  RETURN new_id;
END;
$$;

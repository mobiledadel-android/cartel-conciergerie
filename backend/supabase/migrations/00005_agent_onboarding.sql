-- ============================================
-- Onboarding Agent : documents, compétences
-- ============================================

-- Documents soumis par les agents
CREATE TABLE agent_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'cni', 'photo', 'casier', 'diplome', 'autre'
  label TEXT NOT NULL,
  file_url TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  rejection_reason TEXT,
  reviewed_by UUID REFERENCES admins(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enrichir prestataire_profiles
ALTER TABLE prestataire_profiles ADD COLUMN IF NOT EXISTS onboarding_status TEXT DEFAULT 'incomplete'; -- 'incomplete', 'pending_review', 'approved', 'rejected'
ALTER TABLE prestataire_profiles ADD COLUMN IF NOT EXISTS presentation TEXT;
ALTER TABLE prestataire_profiles ADD COLUMN IF NOT EXISTS experience_years INT DEFAULT 0;
ALTER TABLE prestataire_profiles ADD COLUMN IF NOT EXISTS zones TEXT[] DEFAULT '{}'; -- quartiers/zones couvertes

-- Table des gains
CREATE TABLE agent_earnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  agent_id UUID NOT NULL REFERENCES profiles(id),
  mission_id UUID NOT NULL REFERENCES missions(id),
  amount NUMERIC(10,2) NOT NULL, -- montant gagné (prix - commission)
  commission NUMERIC(10,2) NOT NULL, -- commission plateforme
  status TEXT DEFAULT 'pending', -- 'pending', 'available', 'paid'
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_agent_documents_profile ON agent_documents(profile_id);
CREATE INDEX idx_agent_earnings_agent ON agent_earnings(agent_id);
CREATE INDEX idx_agent_earnings_status ON agent_earnings(status);

-- RLS
ALTER TABLE agent_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_earnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lecture documents" ON agent_documents FOR SELECT USING (true);
CREATE POLICY "Insertion documents" ON agent_documents FOR INSERT WITH CHECK (true);
CREATE POLICY "Mise à jour documents" ON agent_documents FOR UPDATE USING (true);

CREATE POLICY "Lecture gains" ON agent_earnings FOR SELECT USING (true);
CREATE POLICY "Insertion gains" ON agent_earnings FOR INSERT WITH CHECK (true);
CREATE POLICY "Mise à jour gains" ON agent_earnings FOR UPDATE USING (true);

-- Trigger updated_at
CREATE TRIGGER tr_agent_documents_updated
  BEFORE UPDATE ON agent_documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- Fonction : créer automatiquement les gains à la complétion d'une mission
-- Commission : 15%
-- ============================================

CREATE OR REPLACE FUNCTION create_agent_earning()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.prestataire_id IS NOT NULL THEN
    INSERT INTO agent_earnings (agent_id, mission_id, amount, commission, status)
    VALUES (
      NEW.prestataire_id,
      NEW.id,
      COALESCE(NEW.total_price, 0) * 0.85,
      COALESCE(NEW.total_price, 0) * 0.15,
      'pending'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_mission_earning
  AFTER UPDATE ON missions
  FOR EACH ROW EXECUTE FUNCTION create_agent_earning();

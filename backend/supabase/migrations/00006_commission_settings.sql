-- ============================================
-- Paramètres plateforme (commission configurable)
-- ============================================

CREATE TABLE platform_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  label TEXT NOT NULL,
  description TEXT,
  updated_by UUID REFERENCES admins(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Valeurs par défaut
INSERT INTO platform_settings (key, value, label, description) VALUES
  ('commission_rate', '15', 'Taux de commission (%)', 'Pourcentage prélevé sur chaque mission terminée'),
  ('transport_fee', '2500', 'Frais de transport (FCFA)', 'Frais fixes pour les courses, médicaments et colis'),
  ('min_withdrawal', '5000', 'Retrait minimum (FCFA)', 'Montant minimum pour un retrait de gains');

-- RLS
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lecture settings" ON platform_settings FOR SELECT USING (true);
CREATE POLICY "Mise à jour settings" ON platform_settings FOR UPDATE USING (true);

-- Mettre à jour la fonction de calcul des gains pour lire la commission depuis les settings
CREATE OR REPLACE FUNCTION create_agent_earning()
RETURNS TRIGGER AS $$
DECLARE
  commission_pct NUMERIC;
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.prestataire_id IS NOT NULL THEN
    -- Lire le taux depuis platform_settings
    SELECT CAST(value AS NUMERIC) / 100 INTO commission_pct
    FROM platform_settings WHERE key = 'commission_rate';

    IF commission_pct IS NULL THEN commission_pct := 0.15; END IF;

    INSERT INTO agent_earnings (agent_id, mission_id, amount, commission, status)
    VALUES (
      NEW.prestataire_id,
      NEW.id,
      COALESCE(NEW.total_price, 0) * (1 - commission_pct),
      COALESCE(NEW.total_price, 0) * commission_pct,
      'pending'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

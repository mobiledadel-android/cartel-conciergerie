-- ============================================
-- Types de demande : ponctuel, programmé, récurrent
-- ============================================

CREATE TYPE mission_type AS ENUM ('ponctuel', 'programme', 'recurrent');
CREATE TYPE recurrence_frequency AS ENUM ('quotidien', 'hebdomadaire', 'bimensuel', 'mensuel');

-- Ajouter les colonnes à missions
ALTER TABLE missions ADD COLUMN mission_type mission_type DEFAULT 'ponctuel';
ALTER TABLE missions ADD COLUMN recurrence_frequency recurrence_frequency;
ALTER TABLE missions ADD COLUMN recurrence_end_date DATE;
ALTER TABLE missions ADD COLUMN next_occurrence TIMESTAMPTZ;
ALTER TABLE missions ADD COLUMN parent_mission_id UUID REFERENCES missions(id);

-- Config des types autorisés par service (configurable depuis le dashboard)
ALTER TABLE services ADD COLUMN allowed_types mission_type[] DEFAULT '{ponctuel}';
ALTER TABLE services ADD COLUMN allow_recurrence BOOLEAN DEFAULT FALSE;

-- Index
CREATE INDEX idx_missions_type ON missions(mission_type);
CREATE INDEX idx_missions_parent ON missions(parent_mission_id);
CREATE INDEX idx_missions_next_occurrence ON missions(next_occurrence);

-- ============================================
-- Politiques RLS pour les nouvelles colonnes
-- (les politiques existantes couvrent déjà les UPDATE/INSERT)
-- ============================================

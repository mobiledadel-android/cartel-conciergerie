-- ============================================
-- Row Level Security (RLS) Policies
-- Firebase Auth = pas de auth.uid() Supabase
-- On utilise le service_role côté Edge Functions
-- et anon key avec RLS permissif côté client
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE prestataire_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES
-- ============================================

CREATE POLICY "Lecture profils" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Insertion profils" ON profiles
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Mise à jour profils" ON profiles
  FOR UPDATE USING (true);

-- ============================================
-- PRESTATAIRE_PROFILES
-- ============================================

CREATE POLICY "Lecture prestataires" ON prestataire_profiles
  FOR SELECT USING (true);

CREATE POLICY "Insertion prestataires" ON prestataire_profiles
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Mise à jour prestataires" ON prestataire_profiles
  FOR UPDATE USING (true);

-- ============================================
-- SERVICES (lecture seule pour les clients)
-- ============================================

CREATE POLICY "Lecture services" ON services
  FOR SELECT USING (is_active = true);

-- ============================================
-- MISSIONS
-- ============================================

CREATE POLICY "Lecture missions" ON missions
  FOR SELECT USING (true);

CREATE POLICY "Création missions" ON missions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Mise à jour missions" ON missions
  FOR UPDATE USING (true);

-- ============================================
-- PAYMENTS
-- ============================================

CREATE POLICY "Lecture paiements" ON payments
  FOR SELECT USING (true);

CREATE POLICY "Création paiements" ON payments
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Mise à jour paiements" ON payments
  FOR UPDATE USING (true);

-- ============================================
-- REVIEWS
-- ============================================

CREATE POLICY "Lecture avis" ON reviews
  FOR SELECT USING (true);

CREATE POLICY "Création avis" ON reviews
  FOR INSERT WITH CHECK (true);

-- ============================================
-- MESSAGES
-- ============================================

CREATE POLICY "Lecture messages" ON messages
  FOR SELECT USING (true);

CREATE POLICY "Envoi messages" ON messages
  FOR INSERT WITH CHECK (true);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE POLICY "Lecture notifications" ON notifications
  FOR SELECT USING (true);

CREATE POLICY "Mise à jour notifications" ON notifications
  FOR UPDATE USING (true);

CREATE POLICY "Création notifications" ON notifications
  FOR INSERT WITH CHECK (true);

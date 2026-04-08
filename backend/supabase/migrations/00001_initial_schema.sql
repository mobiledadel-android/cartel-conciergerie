-- ============================================
-- Les Conciergeries Cartel - Schema Initial
-- Auth par Firebase (téléphone gratuit)
-- Données dans Supabase
-- ============================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TYPES ENUM
-- ============================================

CREATE TYPE user_role AS ENUM ('client', 'prestataire', 'admin');
CREATE TYPE mission_status AS ENUM ('pending', 'accepted', 'in_progress', 'completed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'refunded');
CREATE TYPE service_category AS ENUM ('courses', 'medicaments', 'accompagnement', 'assistance', 'colis', 'autre');

-- ============================================
-- TABLE: profiles
-- firebase_uid = lien avec Firebase Auth
-- ============================================

CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid TEXT UNIQUE NOT NULL,
  role user_role NOT NULL DEFAULT 'client',
  is_prestataire_enabled BOOLEAN DEFAULT FALSE,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  address TEXT,
  city TEXT DEFAULT 'Libreville',
  location GEOGRAPHY(POINT, 4326),
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: prestataire_profiles
-- ============================================

CREATE TABLE prestataire_profiles (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  bio TEXT,
  competences service_category[] DEFAULT '{}',
  documents_verified BOOLEAN DEFAULT FALSE,
  rating_avg NUMERIC(3,2) DEFAULT 0,
  total_missions INT DEFAULT 0,
  available BOOLEAN DEFAULT TRUE,
  radius_km INT DEFAULT 10
);

-- ============================================
-- TABLE: services
-- ============================================

CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  category service_category NOT NULL,
  description TEXT,
  base_price NUMERIC(10,2) NOT NULL,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: missions
-- ============================================

CREATE TABLE missions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES profiles(id),
  prestataire_id UUID REFERENCES profiles(id),
  service_id UUID NOT NULL REFERENCES services(id),
  status mission_status DEFAULT 'pending',
  description TEXT NOT NULL,
  address_pickup TEXT,
  address_delivery TEXT NOT NULL,
  location_pickup GEOGRAPHY(POINT, 4326),
  location_delivery GEOGRAPHY(POINT, 4326),
  scheduled_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  total_price NUMERIC(10,2),
  commission NUMERIC(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: payments
-- ============================================

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id),
  client_id UUID NOT NULL REFERENCES profiles(id),
  amount NUMERIC(10,2) NOT NULL,
  commission_amount NUMERIC(10,2) DEFAULT 0,
  provider TEXT NOT NULL, -- 'stripe', 'airtel_money', 'moov_money'
  provider_payment_id TEXT,
  status payment_status DEFAULT 'pending',
  callback_data JSONB,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: reviews
-- ============================================

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id),
  reviewer_id UUID NOT NULL REFERENCES profiles(id),
  reviewed_id UUID NOT NULL REFERENCES profiles(id),
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(mission_id, reviewer_id)
);

-- ============================================
-- TABLE: messages (chat)
-- ============================================

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id),
  sender_id UUID NOT NULL REFERENCES profiles(id),
  content TEXT NOT NULL,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: notifications
-- ============================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEX
-- ============================================

CREATE INDEX idx_profiles_firebase_uid ON profiles(firebase_uid);
CREATE INDEX idx_profiles_phone ON profiles(phone);
CREATE INDEX idx_profiles_location ON profiles USING GIST(location);
CREATE INDEX idx_missions_client ON missions(client_id);
CREATE INDEX idx_missions_prestataire ON missions(prestataire_id);
CREATE INDEX idx_missions_status ON missions(status);
CREATE INDEX idx_payments_mission ON payments(mission_id);
CREATE INDEX idx_messages_mission ON messages(mission_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_prestataire_available ON prestataire_profiles(available) WHERE available = TRUE;

-- ============================================
-- TRIGGERS: updated_at automatique
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_profiles_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_missions_updated
  BEFORE UPDATE ON missions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- FONCTION: Mettre à jour la note moyenne du prestataire
-- ============================================

CREATE OR REPLACE FUNCTION update_prestataire_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE prestataire_profiles
  SET
    rating_avg = (
      SELECT COALESCE(AVG(rating), 0)
      FROM reviews
      WHERE reviewed_id = NEW.reviewed_id
    ),
    total_missions = (
      SELECT COUNT(*)
      FROM missions
      WHERE prestataire_id = NEW.reviewed_id AND status = 'completed'
    )
  WHERE id = NEW.reviewed_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_review_rating
  AFTER INSERT OR UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_prestataire_rating();

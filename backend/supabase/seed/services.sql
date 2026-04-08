-- ============================================
-- Services - Les Conciergeries Cartel
-- Prix en FCFA + types autorisés
-- ============================================

DELETE FROM services;

-- COURSES
INSERT INTO services (name, category, description, base_price, allowed_types, allow_recurrence) VALUES
  ('Courses alimentaires', 'courses', 'Faire vos courses au supermarché ou marché local', 3000, '{ponctuel,recurrent}', true),
  ('Courses express', 'courses', 'Achat rapide de quelques articles (moins de 5 articles)', 2000, '{ponctuel}', false),
  ('Courses en gros', 'courses', 'Achat en grande quantité pour la semaine ou le mois', 5000, '{ponctuel,programme}', false);

-- MÉDICAMENTS
INSERT INTO services (name, category, description, base_price, allowed_types, allow_recurrence) VALUES
  ('Récupération de médicaments', 'medicaments', 'Récupérer vos médicaments en pharmacie avec ordonnance', 2500, '{ponctuel,recurrent}', true),
  ('Livraison ordonnance', 'medicaments', 'Livraison de médicaments sur ordonnance à domicile', 3500, '{ponctuel,programme}', false);

-- COLIS
INSERT INTO services (name, category, description, base_price, allowed_types, allow_recurrence) VALUES
  ('Récupération de colis', 'colis', 'Récupérer un colis (DHL, poste, transporteur)', 3000, '{ponctuel}', false),
  ('Envoi de colis', 'colis', 'Déposer un colis à un point de livraison', 3000, '{ponctuel}', false),
  ('Livraison express', 'colis', 'Livraison rapide d''un point A à un point B', 5000, '{ponctuel}', false);

-- ACCOMPAGNEMENT
INSERT INTO services (name, category, description, base_price, allowed_types, allow_recurrence) VALUES
  ('Accompagnement rendez-vous', 'accompagnement', 'Accompagnement à un rendez-vous médical, administratif...', 5000, '{ponctuel,programme}', false),
  ('Accompagnement personne âgée', 'accompagnement', 'Accompagnement et assistance pour personne âgée (sortie, courses)', 4000, '{ponctuel,recurrent}', true),
  ('Accompagnement enfant', 'accompagnement', 'Emmener ou récupérer un enfant (école, activité)', 3500, '{ponctuel,recurrent}', true);

-- ASSISTANCE À DOMICILE
INSERT INTO services (name, category, description, base_price, allowed_types, allow_recurrence) VALUES
  ('Aide ménagère (ponctuelle)', 'assistance', 'Ménage, repassage, nettoyage ponctuel à domicile', 5000, '{ponctuel}', false),
  ('Aide ménagère (mensuelle)', 'assistance', 'Service de ménage régulier - abonnement mensuel (3x/semaine)', 75000, '{recurrent}', true),
  ('Garde d''enfant (journée)', 'assistance', 'Garde d''enfant à domicile pour la journée', 8000, '{ponctuel,programme}', false),
  ('Garde d''enfant (mensuelle)', 'assistance', 'Garde d''enfant régulière - abonnement mensuel', 120000, '{recurrent}', true),
  ('Aide aux personnes âgées (ponctuelle)', 'assistance', 'Assistance à domicile : repas, toilette, compagnie', 7000, '{ponctuel}', false),
  ('Aide aux personnes âgées (mensuelle)', 'assistance', 'Assistance quotidienne à domicile - abonnement mensuel', 150000, '{recurrent}', true),
  ('Cuisinier à domicile', 'assistance', 'Préparation de repas à votre domicile', 10000, '{ponctuel,recurrent}', true),
  ('Bricolage / Dépannage', 'assistance', 'Petits travaux de réparation et bricolage à domicile', 5000, '{ponctuel}', false),
  ('Livraison d''eau', 'assistance', 'Livraison de bidons d''eau à domicile', 2000, '{ponctuel,recurrent}', true);

-- AUTRE
INSERT INTO services (name, category, description, base_price, allowed_types, allow_recurrence) VALUES
  ('Service personnalisé', 'autre', 'Demande de service sur mesure selon vos besoins', 0, '{ponctuel,programme,recurrent}', true);

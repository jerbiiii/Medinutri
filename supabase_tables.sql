-- ============================================================
--  MediNutri — FULL TABLE RESET & SETUP
-- ============================================================

-- ── Drop existing tables (order matters for FK constraints) ─
DROP TABLE IF EXISTS public.chat_history CASCADE;
DROP TABLE IF EXISTS public.nutrition_plans CASCADE;
DROP TABLE IF EXISTS public.ai_doctors CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- ── 1. PROFILES ─────────────────────────────────────────────
CREATE TABLE public.profiles (
  id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name               TEXT NOT NULL DEFAULT '',
  age                INTEGER NOT NULL DEFAULT 0,
  gender             TEXT NOT NULL DEFAULT 'Homme',
  weight             DOUBLE PRECISION NOT NULL DEFAULT 0,
  height             DOUBLE PRECISION NOT NULL DEFAULT 0,
  activity_level     TEXT NOT NULL DEFAULT 'Modérée',
  allergies          TEXT NOT NULL DEFAULT 'Aucune',
  medical_conditions TEXT NOT NULL DEFAULT 'Aucune',
  goal               TEXT NOT NULL DEFAULT 'Équilibre alimentaire',
  photo_path         TEXT,
  created_at         TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT profiles_user_id_unique UNIQUE (user_id)
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "profiles_delete_own" ON public.profiles
  FOR DELETE USING (auth.uid() = user_id);


-- ── 2. CHAT HISTORY ─────────────────────────────────────────
CREATE TABLE public.chat_history (
  id                 UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role               TEXT NOT NULL,
  content            TEXT NOT NULL,
  timestamp          TIMESTAMPTZ DEFAULT now(),
  is_archived        BOOLEAN NOT NULL DEFAULT false,
  conversation_id    TEXT,
  conversation_title TEXT
);

ALTER TABLE public.chat_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_select_own" ON public.chat_history
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "chat_insert_own" ON public.chat_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "chat_update_own" ON public.chat_history
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "chat_delete_own" ON public.chat_history
  FOR DELETE USING (auth.uid() = user_id);


-- ── 3. NUTRITION PLANS ──────────────────────────────────────
CREATE TABLE public.nutrition_plans (
  id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  goal_type            TEXT NOT NULL DEFAULT 'maintenance',
  daily_caloric_target INTEGER NOT NULL DEFAULT 2000,
  title                TEXT NOT NULL DEFAULT '',
  description          TEXT NOT NULL DEFAULT '',
  meals_json           TEXT NOT NULL DEFAULT '{}',
  tips_json            TEXT NOT NULL DEFAULT '[]',
  created_at           TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.nutrition_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "nutrition_select_own" ON public.nutrition_plans
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "nutrition_insert_own" ON public.nutrition_plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "nutrition_update_own" ON public.nutrition_plans
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "nutrition_delete_own" ON public.nutrition_plans
  FOR DELETE USING (auth.uid() = user_id);


-- ── 4. AI DOCTORS ───────────────────────────────────────────
CREATE TABLE public.ai_doctors (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  doctor_id  TEXT NOT NULL,
  name       TEXT NOT NULL,
  specialty  TEXT NOT NULL,
  rating     TEXT NOT NULL DEFAULT '4.5',
  image_url  TEXT NOT NULL DEFAULT '',
  gender     TEXT NOT NULL DEFAULT 'male',
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT ai_doctors_doctor_id_unique UNIQUE (doctor_id)
);

ALTER TABLE public.ai_doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "doctors_select_auth" ON public.ai_doctors
  FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "doctors_insert_auth" ON public.ai_doctors
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "doctors_update_auth" ON public.ai_doctors
  FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "doctors_delete_auth" ON public.ai_doctors
  FOR DELETE USING (auth.role() = 'authenticated');


-- ── 5. MEDICATIONS ──────────────────────────────────────────
DROP TABLE IF EXISTS public.medication_logs CASCADE;
DROP TABLE IF EXISTS public.medications CASCADE;

CREATE TABLE public.medications (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  dosage        TEXT NOT NULL DEFAULT '',
  frequency     TEXT NOT NULL DEFAULT 'daily',
  times_json    TEXT NOT NULL DEFAULT '["08:00"]',
  start_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date      DATE,
  notes         TEXT DEFAULT '',
  color         TEXT DEFAULT '#0D9488',
  icon          TEXT DEFAULT 'medication',
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "medications_select_own" ON public.medications
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "medications_insert_own" ON public.medications
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "medications_update_own" ON public.medications
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "medications_delete_own" ON public.medications
  FOR DELETE USING (auth.uid() = user_id);


-- ── 6. MEDICATION LOGS ──────────────────────────────────────
CREATE TABLE public.medication_logs (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  medication_id   UUID NOT NULL REFERENCES public.medications(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scheduled_time  TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'taken',
  taken_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "med_logs_select_own" ON public.medication_logs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "med_logs_insert_own" ON public.medication_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "med_logs_update_own" ON public.medication_logs
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "med_logs_delete_own" ON public.medication_logs
  FOR DELETE USING (auth.uid() = user_id);

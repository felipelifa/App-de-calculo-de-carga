-- ============================================================
-- BUILDfit DATABASE SCHEMA FOR SUPABASE
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- USERS & AUTH (using Supabase Auth)
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  is_pro BOOLEAN DEFAULT FALSE,
  pro_activated_at TIMESTAMP,
  pro_token_used VARCHAR(255),
  fcm_token VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  age INTEGER,
  biological_sex VARCHAR(10),
  weight_kg FLOAT,
  height_cm FLOAT,
  experience_level VARCHAR(20),
  training_age INTEGER,
  body_fat_category VARCHAR(10),
  primary_goal VARCHAR(30),
  sport_sub_type VARCHAR(30),
  training_modality VARCHAR(30),
  available_days_per_week INTEGER,
  session_duration_minutes INTEGER,
  preferred_style VARCHAR(30),
  sleep_quality VARCHAR(10),
  stress_level VARCHAR(10),
  priority_muscles TEXT[],
  environment VARCHAR(20),
  available_equipment TEXT[],
  disliked_exercises TEXT[],
  favorite_exercises TEXT[],
  health_restrictions TEXT[],
  current_week INTEGER DEFAULT 1,
  exercise_rotation_offset INTEGER DEFAULT 0,
  volume_tolerance VARCHAR(10),
  recovery_capacity VARCHAR(10),
  adherence_rate FLOAT DEFAULT 0.0,
  volume_sensitivity FLOAT DEFAULT 0.0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- EXERCISES
-- ============================================================

CREATE TABLE IF NOT EXISTS exercises (
  id VARCHAR(255) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  name_en VARCHAR(255),
  primary_muscles TEXT[],
  secondary_muscles TEXT[],
  movement_pattern VARCHAR(30),
  equipment TEXT[],
  environment TEXT[],
  category VARCHAR(20),
  difficulty VARCHAR(20),
  restrictions TEXT[],
  rep_range_min INTEGER DEFAULT 8,
  rep_range_max INTEGER DEFAULT 12,
  is_unilateral BOOLEAN DEFAULT FALSE,
  gif_url VARCHAR(255),
  video_url VARCHAR(255),
  cues TEXT[],
  instructions TEXT[],
  substitute_ids TEXT[],
  progression_ids TEXT[],
  regression_ids TEXT[],
  tags TEXT[],
  spinal_load FLOAT DEFAULT 0.0,
  shoulder_stress FLOAT DEFAULT 0.0,
  knee_stress FLOAT DEFAULT 0.0,
  cns_load FLOAT DEFAULT 0.0,
  stability_type VARCHAR(20),
  length_bias VARCHAR(20),
  skill_level INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exercises_primary_muscles ON exercises USING GIN(primary_muscles);
CREATE INDEX IF NOT EXISTS idx_exercises_movement_pattern ON exercises(movement_pattern);
CREATE INDEX IF NOT EXISTS idx_exercises_category ON exercises(category);
CREATE INDEX IF NOT EXISTS idx_exercises_difficulty ON exercises(difficulty);

-- ============================================================
-- USER EXERCISES
-- ============================================================

CREATE TABLE IF NOT EXISTS user_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  series_default INTEGER DEFAULT 3,
  rep_min INTEGER DEFAULT 8,
  rep_max INTEGER DEFAULT 12,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_exercises_user_id ON user_exercises(user_id);

-- ============================================================
-- WORKOUTS
-- ============================================================

CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date TIMESTAMP DEFAULT NOW(),
  week_number INTEGER,
  total_volume FLOAT DEFAULT 0,
  exercise_count INTEGER DEFAULT 0,
  duration_minutes INTEGER,
  notes TEXT,
  session_type VARCHAR(20),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workouts_user_date ON workouts(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_user_week ON workouts(user_id, week_number);

CREATE TABLE IF NOT EXISTS workout_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  exercise_id VARCHAR(255),
  exercise_name VARCHAR(255),
  muscle_group VARCHAR(255),
  notes TEXT,
  rir INTEGER,
  tempo VARCHAR(10),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id ON workout_exercises(workout_id);

CREATE TABLE IF NOT EXISTS workout_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_exercise_id UUID NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
  set_number INTEGER,
  reps INTEGER,
  weight FLOAT,
  volume FLOAT,
  is_warmup BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise_id ON workout_sets(workout_exercise_id);

-- ============================================================
-- PRESCRIPTION & PROGRESSION
-- ============================================================

CREATE TABLE IF NOT EXISTS generated_workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255),
  split_type VARCHAR(30),
  periodization_model VARCHAR(20),
  mesocycle_duration_weeks INTEGER DEFAULT 4,
  preferred_style VARCHAR(30),
  is_active BOOLEAN DEFAULT FALSE,
  sessions JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_generated_workouts_user ON generated_workouts(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS progression_states (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  phase VARCHAR(10) DEFAULT 'normal',
  current_week INTEGER DEFAULT 1,
  is_deload_week BOOLEAN DEFAULT FALSE,
  exercise_states JSONB,
  last_updated TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS volume_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_id VARCHAR(255),
  week_number INTEGER,
  total_volume FLOAT,
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_volume_history_exercise ON volume_history(exercise_id, week_number);
CREATE INDEX IF NOT EXISTS idx_volume_history_user ON volume_history(user_id, week_number);

CREATE TABLE IF NOT EXISTS suggested_progressions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_id VARCHAR(255),
  week_number INTEGER,
  series INTEGER,
  reps INTEGER,
  weight FLOAT,
  volume FLOAT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_suggested_progressions_exercise ON suggested_progressions(exercise_id, week_number);

-- ============================================================
-- PERSONAL RECORDS
-- ============================================================

CREATE TABLE IF NOT EXISTS personal_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_id VARCHAR(255),
  exercise_name VARCHAR(255),
  muscle_group VARCHAR(255),
  max_weight FLOAT DEFAULT 0,
  max_reps INTEGER DEFAULT 0,
  max_volume FLOAT DEFAULT 0,
  achieved_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, exercise_id)
);

CREATE INDEX IF NOT EXISTS idx_personal_records_exercise ON personal_records(exercise_id, updated_at DESC);

-- ============================================================
-- NUTRITION
-- ============================================================

CREATE TABLE IF NOT EXISTS nutrition_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_calories FLOAT DEFAULT 0,
  target_protein FLOAT DEFAULT 0,
  target_carb FLOAT DEFAULT 0,
  target_fat FLOAT DEFAULT 0,
  tmb FLOAT DEFAULT 0,
  tdee FLOAT DEFAULT 0,
  weekly_budget_kcal FLOAT DEFAULT 0,
  carb_cycling BOOLEAN DEFAULT FALSE,
  high_carb_multiplier FLOAT DEFAULT 1.10,
  low_carb_multiplier FLOAT DEFAULT 0.85,
  adherence_score FLOAT DEFAULT 1.0,
  nutritional_fatigue_level INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS nutrition_days (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE,
  total_calories FLOAT DEFAULT 0,
  total_protein FLOAT DEFAULT 0,
  total_carb FLOAT DEFAULT 0,
  total_fat FLOAT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_nutrition_days_user_date ON nutrition_days(user_id, date DESC);

CREATE TABLE IF NOT EXISTS meal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  day_id UUID NOT NULL REFERENCES nutrition_days(id) ON DELETE CASCADE,
  food_id VARCHAR(255),
  food_name VARCHAR(255),
  portion_g FLOAT,
  calories FLOAT,
  protein FLOAT,
  carb FLOAT,
  fat FLOAT,
  meal_type VARCHAR(20),
  is_cheat_meal BOOLEAN DEFAULT FALSE,
  logged_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meal_entries_day_id ON meal_entries(day_id);

-- ============================================================
-- PRO TOKENS
-- ============================================================

CREATE TABLE IF NOT EXISTS pro_tokens (
  code VARCHAR(255) PRIMARY KEY,
  max_redemptions INTEGER DEFAULT -1,
  current_redemptions INTEGER DEFAULT 0,
  label VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pro_token_redemptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  token_code VARCHAR(255) NOT NULL REFERENCES pro_tokens(code) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  redeemed_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(token_code, user_id)
);

CREATE INDEX IF NOT EXISTS idx_pro_token_redemptions_token ON pro_token_redemptions(token_code);

-- ============================================================
-- APP CONFIG
-- ============================================================

CREATE TABLE IF NOT EXISTS apk_versions (
  id VARCHAR(255) PRIMARY KEY DEFAULT 'current',
  version VARCHAR(255),
  release_date TIMESTAMP,
  download_url VARCHAR(255),
  changelog TEXT[],
  min_supported_version VARCHAR(255),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE progression_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_entries ENABLE ROW LEVEL SECURITY;

-- Create policies for service role access
CREATE POLICY "Service role can do anything" ON users FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON user_profiles FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON workouts FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON workout_exercises FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON workout_sets FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON generated_workouts FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON progression_states FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON personal_records FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON nutrition_profiles FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON nutrition_days FOR ALL USING (true);
CREATE POLICY "Service role can do anything" ON meal_entries FOR ALL USING (true);

-- ============================================================
-- MIGRAÇÃO: Garantir que a tabela GeneratedWorkout existe
-- com a estrutura correta para o BuildFit
-- ============================================================

-- Verificar se a tabela existe com snake_case (do schema original)
-- Se existir, criar uma view com nome PascalCase para compatibilidade

-- Opção 1: Criar tabela com PascalCase (se não existir)
CREATE TABLE IF NOT EXISTS "GeneratedWorkout" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255),
  "splitType" VARCHAR(30),
  "periodizationModel" VARCHAR(20),
  "mesocycleDurationWeeks" INTEGER DEFAULT 4,
  "preferredStyle" VARCHAR(30),
  "isActive" BOOLEAN DEFAULT FALSE,
  sessions JSONB,
  "planExplanation" TEXT,
  "createdAt" TIMESTAMP DEFAULT NOW(),
  "updatedAt" TIMESTAMP DEFAULT NOW()
);

-- Criar índice se não existir
CREATE INDEX IF NOT EXISTS idx_generated_workout_user
ON "GeneratedWorkout"("userId", "createdAt" DESC);

-- Verificar se a tabela antiga (snake_case) existe e migrar dados
DO $$
BEGIN
  -- Se a tabela generated_workouts existe, copiar dados para a nova
  IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'generated_workouts') THEN
    INSERT INTO "GeneratedWorkout" (
      id, "userId", name, "splitType", "periodizationModel",
      "mesocycleDurationWeeks", "preferredStyle", "isActive",
      sessions, "createdAt", "updatedAt"
    )
    SELECT
      id, user_id, name, split_type, periodization_model,
      mesocycle_duration_weeks, preferred_style, is_active,
      sessions, created_at, updated_at
    FROM generated_workouts
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Dados migrados de generated_workouts para GeneratedWorkout';
  END IF;
END $$;

-- ============================================================
-- VERIFICAR E CORRIGIR TABELAS RELACIONADAS
-- ============================================================

-- Workout (sessões completadas)
CREATE TABLE IF NOT EXISTS "Workout" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date TIMESTAMP DEFAULT NOW(),
  "weekNumber" INTEGER,
  "totalVolume" FLOAT DEFAULT 0,
  "exerciseCount" INTEGER DEFAULT 0,
  "durationMinutes" INTEGER,
  notes TEXT,
  "sessionType" VARCHAR(30),
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- WorkoutExercise
CREATE TABLE IF NOT EXISTS "WorkoutExercise" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "workoutId" UUID NOT NULL REFERENCES "Workout"(id) ON DELETE CASCADE,
  "exerciseOrder" INTEGER NOT NULL DEFAULT 0,
  "exerciseId" VARCHAR(100) NOT NULL,
  "exerciseName" VARCHAR(255),
  "muscleGroup" VARCHAR(50),
  notes TEXT,
  rir INTEGER,
  tempo VARCHAR(20),
  "createdAt" TIMESTAMP DEFAULT NOW()
);

ALTER TABLE "WorkoutExercise"
  ADD COLUMN IF NOT EXISTS "exerciseOrder" INTEGER NOT NULL DEFAULT 0;

-- WorkoutSet
CREATE TABLE IF NOT EXISTS "WorkoutSet" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "workoutExerciseId" UUID NOT NULL REFERENCES "WorkoutExercise"(id) ON DELETE CASCADE,
  "setNumber" INTEGER NOT NULL,
  reps INTEGER,
  weight FLOAT,
  volume FLOAT,
  "isWarmup" BOOLEAN DEFAULT FALSE,
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- UserProfile
CREATE TABLE IF NOT EXISTS "UserProfile" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  age INTEGER,
  "biologicalSex" VARCHAR(10),
  "weightKg" FLOAT,
  "heightCm" FLOAT,
  "experienceLevel" VARCHAR(20),
  "trainingAge" INTEGER,
  "bodyFatCategory" VARCHAR(10),
  "primaryGoal" VARCHAR(30),
  "sportSubType" VARCHAR(30),
  "trainingModality" VARCHAR(30),
  "availableDaysPerWeek" INTEGER,
  "sessionDurationMinutes" INTEGER,
  "preferredStyle" VARCHAR(30),
  "sleepQuality" VARCHAR(10),
  "stressLevel" VARCHAR(10),
  "priorityMuscles" TEXT[],
  "environment" VARCHAR(20),
  "availableEquipment" TEXT[],
  "dislikedExercises" TEXT[],
  "favoriteExercises" TEXT[],
  "healthRestrictions" TEXT[],
  "currentWeek" INTEGER DEFAULT 1,
  "exerciseRotationOffset" INTEGER DEFAULT 0,
  "createdAt" TIMESTAMP DEFAULT NOW(),
  "updatedAt" TIMESTAMP DEFAULT NOW()
);

-- Exercise (biblioteca remota)
CREATE TABLE IF NOT EXISTS "Exercise" (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  "nameEn" VARCHAR(255),
  "primaryMuscles" TEXT[],
  "secondaryMuscles" TEXT[],
  "movementPattern" VARCHAR(50),
  equipment TEXT[],
  environment TEXT[],
  category VARCHAR(20),
  difficulty VARCHAR(20),
  restrictions TEXT[],
  "repRangeMin" INTEGER DEFAULT 8,
  "repRangeMax" INTEGER DEFAULT 12,
  "isUnilateral" BOOLEAN DEFAULT FALSE,
  "videoUrl" TEXT,
  cues TEXT[],
  instructions TEXT[],
  "substituteIds" TEXT[],
  "progressionIds" TEXT[],
  "regressionIds" TEXT[],
  tags TEXT[],
  "spinalLoad" FLOAT DEFAULT 0,
  "shoulderStress" FLOAT DEFAULT 0,
  "kneeStress" FLOAT DEFAULT 0,
  "cnsLoad" FLOAT DEFAULT 0,
  "stabilityType" VARCHAR(20) DEFAULT 'none',
  "lengthBias" VARCHAR(20) DEFAULT 'mid_range',
  "skillLevel" INTEGER DEFAULT 1,
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- ProgressionState
CREATE TABLE IF NOT EXISTS "ProgressionState" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  phase VARCHAR(10) DEFAULT 'normal',
  "currentWeek" INTEGER DEFAULT 1,
  "isDeloadWeek" BOOLEAN DEFAULT FALSE,
  "exerciseStates" JSONB,
  "lastUpdated" TIMESTAMP DEFAULT NOW()
);

-- PersonalRecord
CREATE TABLE IF NOT EXISTS "PersonalRecord" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "exerciseId" VARCHAR(100) NOT NULL,
  "exerciseName" VARCHAR(255),
  "muscleGroup" VARCHAR(50),
  "maxWeight" FLOAT DEFAULT 0,
  "maxReps" INTEGER DEFAULT 0,
  "maxVolume" FLOAT DEFAULT 0,
  "updatedAt" TIMESTAMP DEFAULT NOW(),
  UNIQUE("userId", "exerciseId")
);

-- ============================================================
-- RLS Policies (permissive para desenvolvimento)
-- ============================================================

ALTER TABLE "GeneratedWorkout" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Workout" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "WorkoutExercise" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "WorkoutSet" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "UserProfile" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Exercise" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ProgressionState" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "PersonalRecord" ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- Gerar políticas permissivas para todas as tabelas
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Service role can do anything' AND tablename = 'GeneratedWorkout') THEN
    CREATE POLICY "Service role can do anything" ON "GeneratedWorkout" FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Service role can do anything' AND tablename = 'Workout') THEN
    CREATE POLICY "Service role can do anything" ON "Workout" FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Service role can do anything' AND tablename = 'WorkoutExercise') THEN
    CREATE POLICY "Service role can do anything" ON "WorkoutExercise" FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Service role can do anything' AND tablename = 'WorkoutSet') THEN
    CREATE POLICY "Service role can do anything" ON "WorkoutSet" FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Service role can do anything' AND tablename = 'UserProfile') THEN
    CREATE POLICY "Service role can do anything" ON "UserProfile" FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Service role can do anything' AND tablename = 'Exercise') THEN
    CREATE POLICY "Service role can do anything" ON "Exercise" FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Service role can do anything' AND tablename = 'ProgressionState') THEN
    CREATE POLICY "Service role can do anything" ON "ProgressionState" FOR ALL USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Service role can do anything' AND tablename = 'PersonalRecord') THEN
    CREATE POLICY "Service role can do anything" ON "PersonalRecord" FOR ALL USING (true);
  END IF;
END $$;

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_workout_user_date ON "Workout"("userId", date DESC);
CREATE INDEX IF NOT EXISTS idx_workout_exercise_workout ON "WorkoutExercise"("workoutId");
CREATE INDEX IF NOT EXISTS idx_workout_set_exercise ON "WorkoutSet"("workoutExerciseId");
CREATE INDEX IF NOT EXISTS idx_exercise_muscles ON "Exercise" USING GIN("primaryMuscles");
CREATE INDEX IF NOT EXISTS idx_exercise_pattern ON "Exercise"("movementPattern");
CREATE INDEX IF NOT EXISTS idx_personal_record_user ON "PersonalRecord"("userId", "exerciseId");

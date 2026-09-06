-- ============================================================
-- FIX SUPABASE AUTH SYNC
-- Execute this in Supabase SQL Editor
-- ============================================================

-- 1. Allow NULL passwordHash (for Supabase Auth users)
ALTER TABLE "User" ALTER COLUMN "passwordHash" DROP NOT NULL;
ALTER TABLE "User" ALTER COLUMN "passwordHash" SET DEFAULT '';

-- 2. Create trigger function to sync auth.users to User table
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public."User" (id, email, name, "passwordHash", "createdAt", "updatedAt")
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    '',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = COALESCE(EXCLUDED.name, "User".name),
    "updatedAt" = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Backfill existing auth users into User table
INSERT INTO public."User" (id, email, name, "passwordHash", "createdAt", "updatedAt")
SELECT
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'name', split_part(au.email, '@', 1)),
  '',
  au.created_at,
  au.updated_at
FROM auth.users au
LEFT JOIN public."User" u ON u.id = au.id
WHERE u.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 5. Fix RLS policies for Workout table
DROP POLICY IF EXISTS "Users can view own workouts" ON "Workout";
DROP POLICY IF EXISTS "Users can insert own workouts" ON "Workout";
DROP POLICY IF EXISTS "Users can update own workouts" ON "Workout";
DROP POLICY IF EXISTS "Users can delete own workouts" ON "Workout";

CREATE POLICY "Users can view own workouts" ON "Workout"
  FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert own workouts" ON "Workout"
  FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update own workouts" ON "Workout"
  FOR UPDATE USING (auth.uid() = "userId");

CREATE POLICY "Users can delete own workouts" ON "Workout"
  FOR DELETE USING (auth.uid() = "userId");

-- 6. Fix RLS policies for UserProfile table
DROP POLICY IF EXISTS "Users can view own profile" ON "UserProfile";
DROP POLICY IF EXISTS "Users can insert own profile" ON "UserProfile";
DROP POLICY IF EXISTS "Users can update own profile" ON "UserProfile";

CREATE POLICY "Users can view own profile" ON "UserProfile"
  FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert own profile" ON "UserProfile"
  FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update own profile" ON "UserProfile"
  FOR UPDATE USING (auth.uid() = "userId");

-- 7. Fix RLS policies for GeneratedWorkout table
DROP POLICY IF EXISTS "Users can view own generated workouts" ON "GeneratedWorkout";
DROP POLICY IF EXISTS "Users can insert own generated workouts" ON "GeneratedWorkout";
DROP POLICY IF EXISTS "Users can update own generated workouts" ON "GeneratedWorkout";
DROP POLICY IF EXISTS "Users can delete own generated workouts" ON "GeneratedWorkout";

CREATE POLICY "Users can view own generated workouts" ON "GeneratedWorkout"
  FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert own generated workouts" ON "GeneratedWorkout"
  FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update own generated workouts" ON "GeneratedWorkout"
  FOR UPDATE USING (auth.uid() = "userId");

CREATE POLICY "Users can delete own generated workouts" ON "GeneratedWorkout"
  FOR DELETE USING (auth.uid() = "userId");

-- 8. Fix RLS policies for ProgressionState table
DROP POLICY IF EXISTS "Users can view own progression" ON "ProgressionState";
DROP POLICY IF EXISTS "Users can insert own progression" ON "ProgressionState";
DROP POLICY IF EXISTS "Users can update own progression" ON "ProgressionState";

CREATE POLICY "Users can view own progression" ON "ProgressionState"
  FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert own progression" ON "ProgressionState"
  FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update own progression" ON "ProgressionState"
  FOR UPDATE USING (auth.uid() = "userId");

-- 9. Fix RLS policies for PersonalRecord table
DROP POLICY IF EXISTS "Users can view own PRs" ON "PersonalRecord";
DROP POLICY IF EXISTS "Users can insert own PRs" ON "PersonalRecord";
DROP POLICY IF EXISTS "Users can update own PRs" ON "PersonalRecord";

CREATE POLICY "Users can view own PRs" ON "PersonalRecord"
  FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert own PRs" ON "PersonalRecord"
  FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update own PRs" ON "PersonalRecord"
  FOR UPDATE USING (auth.uid() = "userId");

-- 10. Fix RLS policies for NutritionProfile table
DROP POLICY IF EXISTS "Users can view own nutrition profile" ON "NutritionProfile";
DROP POLICY IF EXISTS "Users can insert own nutrition profile" ON "NutritionProfile";
DROP POLICY IF EXISTS "Users can update own nutrition profile" ON "NutritionProfile";

CREATE POLICY "Users can view own nutrition profile" ON "NutritionProfile"
  FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert own nutrition profile" ON "NutritionProfile"
  FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update own nutrition profile" ON "NutritionProfile"
  FOR UPDATE USING (auth.uid() = "userId");

-- 11. Fix RLS policies for NutritionDay table
DROP POLICY IF EXISTS "Users can view own nutrition days" ON "NutritionDay";
DROP POLICY IF EXISTS "Users can insert own nutrition days" ON "NutritionDay";
DROP POLICY IF EXISTS "Users can update own nutrition days" ON "NutritionDay";

CREATE POLICY "Users can view own nutrition days" ON "NutritionDay"
  FOR SELECT USING (auth.uid() = "userId");

CREATE POLICY "Users can insert own nutrition days" ON "NutritionDay"
  FOR INSERT WITH CHECK (auth.uid() = "userId");

CREATE POLICY "Users can update own nutrition days" ON "NutritionDay"
  FOR UPDATE USING (auth.uid() = "userId");

-- 12. Fix RLS policies for MealEntry table
DROP POLICY IF EXISTS "Users can view own meals" ON "MealEntry";
DROP POLICY IF EXISTS "Users can insert own meals" ON "MealEntry";
DROP POLICY IF EXISTS "Users can delete own meals" ON "MealEntry";

CREATE POLICY "Users can view own meals" ON "MealEntry"
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM "NutritionDay"
      WHERE "NutritionDay"."id" = "MealEntry"."dayId"
      AND "NutritionDay"."userId" = auth.uid()
    )
  );

CREATE POLICY "Users can insert own meals" ON "MealEntry"
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM "NutritionDay"
      WHERE "NutritionDay"."id" = "MealEntry"."dayId"
      AND "NutritionDay"."userId" = auth.uid()
    )
  );

CREATE POLICY "Users can delete own meals" ON "MealEntry"
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM "NutritionDay"
      WHERE "NutritionDay"."id" = "MealEntry"."dayId"
      AND "NutritionDay"."userId" = auth.uid()
    )
  );

-- 13. Exercise table - public read access
DROP POLICY IF EXISTS "Anyone can view exercises" ON "Exercise";
CREATE POLICY "Anyone can view exercises" ON "Exercise"
  FOR SELECT USING (true);

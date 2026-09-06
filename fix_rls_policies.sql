-- ============================================================
-- FIX RLS POLICIES FOR SUPABASE AUTH
-- Execute this in Supabase SQL Editor
-- ============================================================

-- Drop existing policies that don't work
DROP POLICY IF EXISTS "Service role can do anything" ON "Workout";
DROP POLICY IF EXISTS "Service role can do anything" ON "UserProfile";
DROP POLICY IF EXISTS "Service role can do anything" ON "GeneratedWorkout";
DROP POLICY IF EXISTS "Service role can do anything" ON "ProgressionState";
DROP POLICY IF EXISTS "Service role can do anything" ON "PersonalRecord";
DROP POLICY IF EXISTS "Service role can do anything" ON "NutritionProfile";
DROP POLICY IF EXISTS "Service role can do anything" ON "NutritionDay";
DROP POLICY IF EXISTS "Service role can do anything" ON "MealEntry";
DROP POLICY IF EXISTS "Service role can do anything" ON "Exercise";

-- Create policies for Workout table
CREATE POLICY "Users can view own workouts" ON "Workout"
  FOR SELECT USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can insert own workouts" ON "Workout"
  FOR INSERT WITH CHECK (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can update own workouts" ON "Workout"
  FOR UPDATE USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can delete own workouts" ON "Workout"
  FOR DELETE USING (auth.uid()::text = "userId"::text);

-- Create policies for UserProfile table
CREATE POLICY "Users can view own profile" ON "UserProfile"
  FOR SELECT USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can insert own profile" ON "UserProfile"
  FOR INSERT WITH CHECK (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can update own profile" ON "UserProfile"
  FOR UPDATE USING (auth.uid()::text = "userId"::text);

-- Create policies for GeneratedWorkout table
CREATE POLICY "Users can view own generated workouts" ON "GeneratedWorkout"
  FOR SELECT USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can insert own generated workouts" ON "GeneratedWorkout"
  FOR INSERT WITH CHECK (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can update own generated workouts" ON "GeneratedWorkout"
  FOR UPDATE USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can delete own generated workouts" ON "GeneratedWorkout"
  FOR DELETE USING (auth.uid()::text = "userId"::text);

-- Create policies for ProgressionState table
CREATE POLICY "Users can view own progression" ON "ProgressionState"
  FOR SELECT USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can insert own progression" ON "ProgressionState"
  FOR INSERT WITH CHECK (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can update own progression" ON "ProgressionState"
  FOR UPDATE USING (auth.uid()::text = "userId"::text);

-- Create policies for PersonalRecord table
CREATE POLICY "Users can view own PRs" ON "PersonalRecord"
  FOR SELECT USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can insert own PRs" ON "PersonalRecord"
  FOR INSERT WITH CHECK (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can update own PRs" ON "PersonalRecord"
  FOR UPDATE USING (auth.uid()::text = "userId"::text);

-- Create policies for NutritionProfile table
CREATE POLICY "Users can view own nutrition profile" ON "NutritionProfile"
  FOR SELECT USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can insert own nutrition profile" ON "NutritionProfile"
  FOR INSERT WITH CHECK (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can update own nutrition profile" ON "NutritionProfile"
  FOR UPDATE USING (auth.uid()::text = "userId"::text);

-- Create policies for NutritionDay table
CREATE POLICY "Users can view own nutrition days" ON "NutritionDay"
  FOR SELECT USING (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can insert own nutrition days" ON "NutritionDay"
  FOR INSERT WITH CHECK (auth.uid()::text = "userId"::text);

CREATE POLICY "Users can update own nutrition days" ON "NutritionDay"
  FOR UPDATE USING (auth.uid()::text = "userId"::text);

-- Create policies for MealEntry table
CREATE POLICY "Users can view own meals" ON "MealEntry"
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM "NutritionDay" 
      WHERE "NutritionDay"."id" = "MealEntry"."dayId" 
      AND "NutritionDay"."userId"::text = auth.uid()::text
    )
  );

CREATE POLICY "Users can insert own meals" ON "MealEntry"
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM "NutritionDay" 
      WHERE "NutritionDay"."id" = "MealEntry"."dayId" 
      AND "NutritionDay"."userId"::text = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete own meals" ON "MealEntry"
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM "NutritionDay" 
      WHERE "NutritionDay"."id" = "MealEntry"."dayId" 
      AND "NutritionDay"."userId"::text = auth.uid()::text
    )
  );

-- Exercise table - public read access (no user_id)
CREATE POLICY "Anyone can view exercises" ON "Exercise"
  FOR SELECT USING (true);

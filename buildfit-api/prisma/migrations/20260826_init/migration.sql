-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "firebaseUid" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "isPro" BOOLEAN NOT NULL DEFAULT false,
    "proActivatedAt TIMESTAMP(3),
    "proTokenUsed" TEXT,
    "fcmToken" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "age" INTEGER,
    "biologicalSex" VARCHAR(10),
    "weightKg" DOUBLE PRECISION,
    "heightCm" DOUBLE PRECISION,
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
    "currentWeek" INTEGER NOT NULL DEFAULT 1,
    "exerciseRotationOffset" INTEGER NOT NULL DEFAULT 0,
    "volumeTolerance" VARCHAR(10),
    "recoveryCapacity" VARCHAR(10),
    "adherenceRate" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "volumeSensitivity" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Exercise" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameEn" TEXT,
    "primaryMuscles" TEXT[],
    "secondaryMuscles" TEXT[],
    "movementPattern" VARCHAR(30) NOT NULL,
    "equipment" TEXT[],
    "environment" TEXT[],
    "category" VARCHAR(20) NOT NULL,
    "difficulty" VARCHAR(20) NOT NULL,
    "restrictions" TEXT[],
    "repRangeMin" INTEGER NOT NULL DEFAULT 8,
    "repRangeMax" INTEGER NOT NULL DEFAULT 12,
    "isUnilateral" BOOLEAN NOT NULL DEFAULT false,
    "gifUrl" TEXT,
    "videoUrl" TEXT,
    "cues" TEXT[],
    "instructions" TEXT[],
    "substituteIds" TEXT[],
    "progressionIds" TEXT[],
    "regressionIds" TEXT[],
    "tags" TEXT[],
    "spinalLoad" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "shoulderStress" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "kneeStress" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "cnsLoad" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "stabilityType" VARCHAR(20),
    "lengthBias" VARCHAR(20),
    "skillLevel" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Exercise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserExercise" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "seriesDefault" INTEGER NOT NULL DEFAULT 3,
    "repMin" INTEGER NOT NULL DEFAULT 8,
    "repMax" INTEGER NOT NULL DEFAULT 12,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserExercise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Workout" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "weekNumber" INTEGER NOT NULL,
    "totalVolume" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "exerciseCount" INTEGER NOT NULL DEFAULT 0,
    "durationMinutes" INTEGER,
    "notes" TEXT,
    "sessionType" VARCHAR(20),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Workout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkoutExercise" (
    "id" TEXT NOT NULL,
    "workoutId" TEXT NOT NULL,
    "exerciseId" TEXT NOT NULL,
    "exerciseName" TEXT NOT NULL,
    "muscleGroup" TEXT,
    "notes" TEXT,
    "rir" INTEGER,
    "tempo" VARCHAR(10),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WorkoutExercise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkoutSet" (
    "id" TEXT NOT NULL,
    "workoutExerciseId" TEXT NOT NULL,
    "setNumber" INTEGER NOT NULL,
    "reps" INTEGER NOT NULL,
    "weight" DOUBLE PRECISION NOT NULL,
    "volume" DOUBLE PRECISION NOT NULL,
    "isWarmup" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "WorkoutSet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GeneratedWorkout" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "splitType" VARCHAR(30) NOT NULL,
    "periodizationModel" VARCHAR(20),
    "mesocycleDurationWeeks" INTEGER NOT NULL DEFAULT 4,
    "preferredStyle" VARCHAR(30),
    "isActive" BOOLEAN NOT NULL DEFAULT false,
    "sessions" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "GeneratedWorkout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProgressionState" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "phase" VARCHAR(10) NOT NULL DEFAULT 'normal',
    "currentWeek" INTEGER NOT NULL DEFAULT 1,
    "isDeloadWeek" BOOLEAN NOT NULL DEFAULT false,
    "exerciseStates" JSONB NOT NULL,
    "lastUpdated" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProgressionState_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VolumeHistory" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "exerciseId" TEXT NOT NULL,
    "weekNumber" INTEGER NOT NULL,
    "totalVolume" DOUBLE PRECISION NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VolumeHistory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SuggestedProgression" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "exerciseId" TEXT NOT NULL,
    "weekNumber" INTEGER NOT NULL,
    "series" INTEGER NOT NULL,
    "reps" INTEGER NOT NULL,
    "weight" DOUBLE PRECISION NOT NULL,
    "volume" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SuggestedProgression_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PersonalRecord" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "exerciseId" TEXT NOT NULL,
    "exerciseName" TEXT NOT NULL,
    "muscleGroup" TEXT,
    "maxWeight" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "maxReps" INTEGER NOT NULL DEFAULT 0,
    "maxVolume" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "achievedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PersonalRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NutritionProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "targetCalories" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "targetProtein" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "targetCarb" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "targetFat" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "tmb" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "tdee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "weeklyBudgetKcal" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "carbCycling" BOOLEAN NOT NULL DEFAULT false,
    "highCarbMultiplier" DOUBLE PRECISION NOT NULL DEFAULT 1.1,
    "lowCarbMultiplier" DOUBLE PRECISION NOT NULL DEFAULT 0.85,
    "adherenceScore" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "nutritionalFatigueLevel" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NutritionProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NutritionDay" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "totalCalories" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalProtein" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalCarb" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalFat" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NutritionDay_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MealEntry" (
    "id" TEXT NOT NULL,
    "dayId" TEXT NOT NULL,
    "foodId" TEXT,
    "foodName" TEXT NOT NULL,
    "portionG" DOUBLE PRECISION NOT NULL,
    "calories" DOUBLE PRECISION NOT NULL,
    "protein" DOUBLE PRECISION NOT NULL,
    "carb" DOUBLE PRECISION NOT NULL,
    "fat" DOUBLE PRECISION NOT NULL,
    "mealType" VARCHAR(20) NOT NULL,
    "isCheatMeal" BOOLEAN NOT NULL DEFAULT false,
    "loggedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MealEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProToken" (
    "code" TEXT NOT NULL,
    "maxRedemptions" INTEGER NOT NULL DEFAULT -1,
    "currentRedemptions" INTEGER NOT NULL DEFAULT 0,
    "label" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3),

    CONSTRAINT "ProToken_pkey" PRIMARY KEY ("code")
);

-- CreateTable
CREATE TABLE "ProTokenRedemption" (
    "id" TEXT NOT NULL,
    "tokenCode" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "redeemedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProTokenRedemption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ApkVersion" (
    "id" TEXT NOT NULL DEFAULT 'current',
    "version" TEXT NOT NULL,
    "releaseDate" TIMESTAMP(3) NOT NULL,
    "downloadUrl" TEXT NOT NULL,
    "changelog" TEXT[],
    "minSupportedVersion" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ApkVersion_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_firebaseUid_key" ON "User"("firebaseUid");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "UserProfile_userId_key" ON "UserProfile"("userId");

-- CreateIndex
CREATE INDEX "Exercise_primaryMuscles_idx" ON "Exercise"("primaryMuscles");

-- CreateIndex
CREATE INDEX "Exercise_movementPattern_idx" ON "Exercise"("movementPattern");

-- CreateIndex
CREATE INDEX "Exercise_category_idx" ON "Exercise"("category");

-- CreateIndex
CREATE INDEX "Exercise_difficulty_idx" ON "Exercise"("difficulty");

-- CreateIndex
CREATE INDEX "UserExercise_userId_idx" ON "UserExercise"("userId");

-- CreateIndex
CREATE INDEX "Workout_userId_date_idx" ON "Workout"("userId", "date" DESC);

-- CreateIndex
CREATE INDEX "Workout_userId_weekNumber_idx" ON "Workout"("userId", "weekNumber");

-- CreateIndex
CREATE INDEX "WorkoutExercise_workoutId_idx" ON "WorkoutExercise"("workoutId");

-- CreateIndex
CREATE INDEX "WorkoutExercise_exerciseId_idx" ON "WorkoutExercise"("exerciseId");

-- CreateIndex
CREATE INDEX "WorkoutSet_workoutExerciseId_idx" ON "WorkoutSet"("workoutExerciseId");

-- CreateIndex
CREATE INDEX "GeneratedWorkout_userId_createdAt_idx" ON "GeneratedWorkout"("userId", "createdAt" DESC);

-- CreateIndex
CREATE INDEX "ProgressionState_userId_idx" ON "ProgressionState"("userId");

-- CreateIndex
CREATE INDEX "VolumeHistory_exerciseId_weekNumber_idx" ON "VolumeHistory"("exerciseId", "weekNumber");

-- CreateIndex
CREATE INDEX "VolumeHistory_userId_weekNumber_idx" ON "VolumeHistory"("userId", "weekNumber");

-- CreateIndex
CREATE INDEX "SuggestedProgression_exerciseId_weekNumber_idx" ON "SuggestedProgression"("exerciseId", "weekNumber");

-- CreateIndex
CREATE INDEX "SuggestedProgression_userId_weekNumber_idx" ON "SuggestedProgression"("userId", "weekNumber");

-- CreateIndex
CREATE UNIQUE INDEX "PersonalRecord_userId_exerciseId_key" ON "PersonalRecord"("userId", "exerciseId");

-- CreateIndex
CREATE INDEX "PersonalRecord_exerciseId_updatedAt_idx" ON "PersonalRecord"("exerciseId", "updatedAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "NutritionProfile_userId_key" ON "NutritionProfile"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "NutritionDay_userId_date_key" ON "NutritionDay"("userId", "date");

-- CreateIndex
CREATE INDEX "NutritionDay_userId_date_idx" ON "NutritionDay"("userId", "date" DESC);

-- CreateIndex
CREATE INDEX "MealEntry_dayId_idx" ON "MealEntry"("dayId");

-- CreateIndex
CREATE UNIQUE INDEX "ProTokenRedemption_tokenCode_userId_key" ON "ProTokenRedemption"("tokenCode", "userId");

-- CreateIndex
CREATE INDEX "ProTokenRedemption_tokenCode_idx" ON "ProTokenRedemption"("tokenCode");

-- AddForeignKey
ALTER TABLE "UserProfile" ADD CONSTRAINT "UserProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserExercise" ADD CONSTRAINT "UserExercise_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Workout" ADD CONSTRAINT "Workout_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutExercise" ADD CONSTRAINT "WorkoutExercise_workoutId_fkey" FOREIGN KEY ("workoutId") REFERENCES "Workout"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSet" ADD CONSTRAINT "WorkoutSet_workoutExerciseId_fkey" FOREIGN KEY ("workoutExerciseId") REFERENCES "WorkoutExercise"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GeneratedWorkout" ADD CONSTRAINT "GeneratedWorkout_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProgressionState" ADD CONSTRAINT "ProgressionState_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VolumeHistory" ADD CONSTRAINT "VolumeHistory_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SuggestedProgression" ADD CONSTRAINT "SuggestedProgression_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PersonalRecord" ADD CONSTRAINT "PersonalRecord_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionProfile" ADD CONSTRAINT "NutritionProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionDay" ADD CONSTRAINT "NutritionDay_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealEntry" ADD CONSTRAINT "MealEntry_dayId_fkey" FOREIGN KEY ("dayId") REFERENCES "NutritionDay"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProTokenRedemption" ADD CONSTRAINT "ProTokenRedemption_tokenCode_fkey" FOREIGN KEY ("tokenCode") REFERENCES "ProToken"("code") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProTokenRedemption" ADD CONSTRAINT "ProTokenRedemption_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

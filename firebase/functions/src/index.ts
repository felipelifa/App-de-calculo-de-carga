import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  calcVolume,
  calcWeekTarget,
  generateSuggestions,
} from "./volumeEngine";
import type {
  WorkoutExercise,
  ProgressionWeek,
  Suggestion,
  VolumeHistoryEntry,
} from "./types";

// Push Notifications
export {
  onPersonalRecordCreated,
  onDeloadActivated,
  notifyInactiveUsers,
} from "./pushNotifications";

export {
  redeemProToken,
} from "./proToken";

// ════════════════════════════════════════════════════════════
// Firebase Admin Init (only once per cold start)
// ════════════════════════════════════════════════════════════
const getDb = () => {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }
  return admin.firestore();
};

// ════════════════════════════════════════════════════════════
// TRIGGER: onWorkoutSave
// Fires when a workout/exercises document is created or updated.
// Recalculates volumeHistory for the user + exercise + week.
// ════════════════════════════════════════════════════════════
export const onWorkoutExerciseSave = functions.firestore
  .document("users/{uid}/workouts/{wId}/exercises/{weId}")
  .onWrite(async (change, context) => {
    const db = getDb();
    const { uid, wId } = context.params;

    // If deleted, we still recalculate (volume drops to 0 removal)
    const newData = change.after.exists
      ? (change.after.data() as WorkoutExercise)
      : null;

    if (newData) {
      // Validate volume matches declaration
      const computedVolume = calcVolume(
        newData.series,
        newData.reps,
        newData.weight
      );
      const tolerance = 0.01;
      if (Math.abs(computedVolume - newData.volume) > tolerance) {
        functions.logger.warn(
          `Volume mismatch for weId=${context.params.weId}: ` +
            `declared=${newData.volume}, computed=${computedVolume}`
        );
        // Correct the volume server-side
        await change.after.ref.update({ volume: computedVolume });
      }
    }

    // Aggregate total volume for this exercise in this week
    const workoutDoc = await db
      .doc(`users/${uid}/workouts/${wId}`)
      .get();
    if (!workoutDoc.exists) return null;

    const weekNumber: number = workoutDoc.data()?.weekNumber ?? 0;
    const exerciseId: string = newData?.exerciseId ?? change.before.data()?.exerciseId;

    if (!exerciseId || !weekNumber) return null;

    // Sum all workout_exercise volumes for this exercise across the same week
    const workoutsSnap = await db
      .collection(`users/${uid}/workouts`)
      .where("weekNumber", "==", weekNumber)
      .get();

    let totalVolume = 0;
    for (const wDoc of workoutsSnap.docs) {
      const exSnap = await db
        .collection(`users/${uid}/workouts/${wDoc.id}/exercises`)
        .where("exerciseId", "==", exerciseId)
        .get();
      for (const ex of exSnap.docs) {
        totalVolume += (ex.data() as WorkoutExercise).volume ?? 0;
      }
    }

    // Upsert volumeHistory
    const historyRef = db
      .collection(`users/${uid}/volumeHistory`)
      .doc(`${exerciseId}_week${weekNumber}`);

    const entry: VolumeHistoryEntry = {
      exerciseId,
      weekNumber,
      totalVolume,
      updatedAt: admin.firestore.Timestamp.now(),
    };

    await historyRef.set(entry, { merge: true });
    functions.logger.info(
      `volumeHistory updated: exercise=${exerciseId} week=${weekNumber} vol=${totalVolume}`
    );
    return null;
  });

// ════════════════════════════════════════════════════════════
// CALLABLE: generateProgressionSuggestions
// Called by the Flutter app when the user opens the
// Suggestions screen. The app does the same math locally,
// but this serves as authoritative validation.
// ════════════════════════════════════════════════════════════
export const generateProgressionSuggestions = functions.https.onCall(
  async (data, context) => {
    const db = getDb();
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    const uid = context.auth.uid;
    const { exerciseId, weekNumber } = data as {
      exerciseId: string;
      weekNumber: number;
    };

    if (!exerciseId || !weekNumber) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "exerciseId and weekNumber are required"
      );
    }

    // Get exercise defaults
    const exerciseDoc = await db
      .doc(`users/${uid}/exercises/${exerciseId}`)
      .get();
    if (!exerciseDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Exercise not found");
    }
    const exercise = exerciseDoc.data()!;

    // Get previous week volume from history
    const prevWeek = weekNumber - 1;
    const prevHistoryId = `${exerciseId}_week${prevWeek}`;
    const prevHistoryDoc = await db
      .doc(`users/${uid}/volumeHistory/${prevHistoryId}`)
      .get();
    const prevVolume: number = prevHistoryDoc.exists
      ? (prevHistoryDoc.data() as VolumeHistoryEntry).totalVolume
      : 0;

    // Get the progression config for this week
    const pwSnap = await db
      .collection(`users/${uid}/progressionWeeks`)
      .where("weekNumber", "==", weekNumber)
      .limit(1)
      .get();

    const progressionPercent: number = pwSnap.empty
      ? 0
      : (pwSnap.docs[0].data() as ProgressionWeek).progressionPercent;

    // Calculate target volume
    const targetVolume = prevVolume > 0
      ? calcWeekTarget(prevVolume, progressionPercent)
      : 0;

    // Generate suggestions
    const suggestions: Suggestion[] = generateSuggestions({
      prevVolume,
      targetVolume: targetVolume > 0 ? targetVolume : prevVolume,
      fixedSeries: exercise.seriesDefault,
      repMin: exercise.repMin,
      repMax: exercise.repMax,
      weekNumber,
    });

    // Persist suggestions in Firestore (overwrite previous)
    const batch = db.batch();
    // Clear old suggestions for this exercise + week
    const oldSuggSnap = await db
      .collection(`users/${uid}/suggestedProgressions`)
      .where("exerciseId", "==", exerciseId)
      .where("weekNumber", "==", weekNumber)
      .get();
    oldSuggSnap.docs.forEach((d) => batch.delete(d.ref));

    // Write new suggestions
    suggestions.forEach((s, i) => {
      const ref = db
        .collection(`users/${uid}/suggestedProgressions`)
        .doc(`${exerciseId}_week${weekNumber}_${i}`);
      batch.set(ref, { ...s, exerciseId });
    });
    await batch.commit();

    return {
      prevVolume,
      targetVolume,
      progressionPercent,
      suggestions,
    };
  }
);

// ════════════════════════════════════════════════════════════
// CALLABLE: calculatePeriodizationPlan
// Given a list of ProgressionWeek configs and a base volume,
// returns the full target volume schedule for each week.
// ════════════════════════════════════════════════════════════
export const calculatePeriodizationPlan = functions.https.onCall(
  async (data, context) => {
    const db = getDb();
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    const uid = context.auth.uid;
    const { exerciseId, startWeek } = data as {
      exerciseId: string;
      startWeek: number;
    };

    // Load progression weeks for this user, sorted by weekNumber
    const pwSnap = await db
      .collection(`users/${uid}/progressionWeeks`)
      .orderBy("weekNumber", "asc")
      .get();
    const weeks = pwSnap.docs.map((d) => d.data() as ProgressionWeek);

    if (weeks.length === 0) return { plan: [] };

    // Get baseline volume from history
    const baseHistoryId = `${exerciseId}_week${startWeek - 1}`;
    const baseDoc = await db
      .doc(`users/${uid}/volumeHistory/${baseHistoryId}`)
      .get();
    let currentVolume: number = baseDoc.exists
      ? (baseDoc.data() as VolumeHistoryEntry).totalVolume
      : 0;

    const plan: Array<{
      weekNumber: number;
      type: string;
      progressionPercent: number;
      targetVolume: number;
    }> = [];

    for (const week of weeks) {
      const targetVolume = currentVolume > 0
        ? calcWeekTarget(currentVolume, week.progressionPercent)
        : 0;
      plan.push({
        weekNumber: week.weekNumber,
        type: week.type,
        progressionPercent: week.progressionPercent,
        targetVolume: Math.round(targetVolume * 100) / 100,
      });
      // For deload weeks, don't update currentVolume (next week bases on pre-deload)
      if (week.type !== "deload") {
        currentVolume = targetVolume;
      }
    }

    return { plan };
  }
);

// ════════════════════════════════════════════════════════════
// CALLABLE: getApkVersion
// Returns the current APK version metadata stored in Firestore.
// Used by the Flutter app on startup to check for updates.
// ════════════════════════════════════════════════════════════
export const getApkVersion = functions.https.onCall(async (_data, context) => {
  const db = getDb();
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required"
    );
  }
  const versionDoc = await db.doc("config/apkVersion").get();
  if (!versionDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Version info not found");
  }
  return versionDoc.data();
});

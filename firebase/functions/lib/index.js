"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getApkVersion = exports.calculatePeriodizationPlan = exports.generateProgressionSuggestions = exports.onWorkoutExerciseSave = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const volumeEngine_1 = require("./volumeEngine");
// ════════════════════════════════════════════════════════════
// Firebase Admin Init (only once per cold start)
// ════════════════════════════════════════════════════════════
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();
// ════════════════════════════════════════════════════════════
// TRIGGER: onWorkoutSave
// Fires when a workout/exercises document is created or updated.
// Recalculates volumeHistory for the user + exercise + week.
// ════════════════════════════════════════════════════════════
exports.onWorkoutExerciseSave = functions.firestore
    .document("users/{uid}/workouts/{wId}/exercises/{weId}")
    .onWrite(async (change, context) => {
    var _a, _b, _c, _d, _e;
    const { uid, wId } = context.params;
    // If deleted, we still recalculate (volume drops to 0 removal)
    const newData = change.after.exists
        ? change.after.data()
        : null;
    if (newData) {
        // Validate volume matches declaration
        const computedVolume = (0, volumeEngine_1.calcVolume)(newData.series, newData.reps, newData.weight);
        const tolerance = 0.01;
        if (Math.abs(computedVolume - newData.volume) > tolerance) {
            functions.logger.warn(`Volume mismatch for weId=${context.params.weId}: ` +
                `declared=${newData.volume}, computed=${computedVolume}`);
            // Correct the volume server-side
            await change.after.ref.update({ volume: computedVolume });
        }
    }
    // Aggregate total volume for this exercise in this week
    const workoutDoc = await db
        .doc(`users/${uid}/workouts/${wId}`)
        .get();
    if (!workoutDoc.exists)
        return null;
    const weekNumber = (_b = (_a = workoutDoc.data()) === null || _a === void 0 ? void 0 : _a.weekNumber) !== null && _b !== void 0 ? _b : 0;
    const exerciseId = (_c = newData === null || newData === void 0 ? void 0 : newData.exerciseId) !== null && _c !== void 0 ? _c : (_d = change.before.data()) === null || _d === void 0 ? void 0 : _d.exerciseId;
    if (!exerciseId || !weekNumber)
        return null;
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
            totalVolume += (_e = ex.data().volume) !== null && _e !== void 0 ? _e : 0;
        }
    }
    // Upsert volumeHistory
    const historyRef = db
        .collection(`users/${uid}/volumeHistory`)
        .doc(`${exerciseId}_week${weekNumber}`);
    const entry = {
        exerciseId,
        weekNumber,
        totalVolume,
        updatedAt: admin.firestore.Timestamp.now(),
    };
    await historyRef.set(entry, { merge: true });
    functions.logger.info(`volumeHistory updated: exercise=${exerciseId} week=${weekNumber} vol=${totalVolume}`);
    return null;
});
// ════════════════════════════════════════════════════════════
// CALLABLE: generateProgressionSuggestions
// Called by the Flutter app when the user opens the
// Suggestions screen. The app does the same math locally,
// but this serves as authoritative validation.
// ════════════════════════════════════════════════════════════
exports.generateProgressionSuggestions = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    const uid = context.auth.uid;
    const { exerciseId, weekNumber } = data;
    if (!exerciseId || !weekNumber) {
        throw new functions.https.HttpsError("invalid-argument", "exerciseId and weekNumber are required");
    }
    // Get exercise defaults
    const exerciseDoc = await db
        .doc(`users/${uid}/exercises/${exerciseId}`)
        .get();
    if (!exerciseDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Exercise not found");
    }
    const exercise = exerciseDoc.data();
    // Get previous week volume from history
    const prevWeek = weekNumber - 1;
    const prevHistoryId = `${exerciseId}_week${prevWeek}`;
    const prevHistoryDoc = await db
        .doc(`users/${uid}/volumeHistory/${prevHistoryId}`)
        .get();
    const prevVolume = prevHistoryDoc.exists
        ? prevHistoryDoc.data().totalVolume
        : 0;
    // Get the progression config for this week
    const pwSnap = await db
        .collection(`users/${uid}/progressionWeeks`)
        .where("weekNumber", "==", weekNumber)
        .limit(1)
        .get();
    const progressionPercent = pwSnap.empty
        ? 0
        : pwSnap.docs[0].data().progressionPercent;
    // Calculate target volume
    const targetVolume = prevVolume > 0
        ? (0, volumeEngine_1.calcWeekTarget)(prevVolume, progressionPercent)
        : 0;
    // Generate suggestions
    const suggestions = (0, volumeEngine_1.generateSuggestions)({
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
        batch.set(ref, Object.assign(Object.assign({}, s), { exerciseId }));
    });
    await batch.commit();
    return {
        prevVolume,
        targetVolume,
        progressionPercent,
        suggestions,
    };
});
// ════════════════════════════════════════════════════════════
// CALLABLE: calculatePeriodizationPlan
// Given a list of ProgressionWeek configs and a base volume,
// returns the full target volume schedule for each week.
// ════════════════════════════════════════════════════════════
exports.calculatePeriodizationPlan = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    const uid = context.auth.uid;
    const { exerciseId, startWeek } = data;
    // Load progression weeks for this user, sorted by weekNumber
    const pwSnap = await db
        .collection(`users/${uid}/progressionWeeks`)
        .orderBy("weekNumber", "asc")
        .get();
    const weeks = pwSnap.docs.map((d) => d.data());
    if (weeks.length === 0)
        return { plan: [] };
    // Get baseline volume from history
    const baseHistoryId = `${exerciseId}_week${startWeek - 1}`;
    const baseDoc = await db
        .doc(`users/${uid}/volumeHistory/${baseHistoryId}`)
        .get();
    let currentVolume = baseDoc.exists
        ? baseDoc.data().totalVolume
        : 0;
    const plan = [];
    for (const week of weeks) {
        const targetVolume = currentVolume > 0
            ? (0, volumeEngine_1.calcWeekTarget)(currentVolume, week.progressionPercent)
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
});
// ════════════════════════════════════════════════════════════
// CALLABLE: getApkVersion
// Returns the current APK version metadata stored in Firestore.
// Used by the Flutter app on startup to check for updates.
// ════════════════════════════════════════════════════════════
exports.getApkVersion = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    const versionDoc = await db.doc("config/apkVersion").get();
    if (!versionDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Version info not found");
    }
    return versionDoc.data();
});
//# sourceMappingURL=index.js.map
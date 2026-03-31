// ============================================================
// Core math types shared between Cloud Functions and Flutter
// ============================================================

export interface VolumeHistoryEntry {
  exerciseId: string;
  weekNumber: number;
  totalVolume: number;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface WorkoutExercise {
  exerciseId: string;
  series: number;
  reps: number;
  weight: number; // kg
  volume: number; // series × reps × weight
}

export interface Exercise {
  name: string;
  seriesDefault: number;
  repMin: number;
  repMax: number;
}

export interface ProgressionWeek {
  weekNumber: number;
  progressionPercent: number; // e.g. 2 = +2%, -10 = deload -10%
  type: "base" | "progression" | "deload";
}

export interface Suggestion {
  series: number;
  reps: number;
  weight: number; // rounded to nearest 2.5 kg
  volume: number;
  weekNumber: number;
}

export type ApkVersionInfo = {
  version: string; // semver, e.g. "1.0.0"
  releaseDate: FirebaseFirestore.Timestamp;
  downloadUrl: string;
  changelog: string[];
  minSupportedVersion: string;
};

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.calcVolume = calcVolume;
exports.calcWeekTarget = calcWeekTarget;
exports.calcWeight = calcWeight;
exports.roundToNearest = roundToNearest;
exports.generateSuggestions = generateSuggestions;
// ════════════════════════════════════════════════════════════
// VOLUME ENGINE  –  Pure math, no Firebase imports
// Mirrors the logic in Flutter's core/math/volume_calculator.dart
// ════════════════════════════════════════════════════════════
/**
 * Base volume calculation.
 * volume = series × reps × weight
 */
function calcVolume(series, reps, weight) {
    return series * reps * weight;
}
/**
 * Target volume for a given week based on progression %.
 * volume_target = volume_previous × (1 + progressionPercent / 100)
 */
function calcWeekTarget(prevVolume, progressionPercent) {
    return prevVolume * (1 + progressionPercent / 100);
}
/**
 * Raw weight needed to hit a target volume with given series × reps.
 * weight = target_volume / (series × reps)
 */
function calcWeight(targetVolume, series, reps) {
    if (series <= 0 || reps <= 0)
        throw new Error("series and reps must be > 0");
    return targetVolume / (series * reps);
}
/**
 * Round a value to the nearest multiple (default 2.5 kg).
 * e.g. roundToNearest(47.3, 2.5) → 47.5
 */
function roundToNearest(value, multiple = 2.5) {
    return Math.round(value / multiple) * multiple;
}
/**
 * Generates all valid rep/weight combinations for the next week.
 *
 * Rules:
 *  1. Series is fixed per exercise.
 *  2. Reps ∈ [repMin, repMax] (default 8–12).
 *  3. Weight is calculated from target volume and rounded to nearest 2.5 kg.
 *  4. Only combinations where volume_new >= volume_previous are included.
 *  5. Results are sorted ascending by volume (smallest valid increment first).
 */
function generateSuggestions(params) {
    const { prevVolume, targetVolume, fixedSeries, repMin = 8, repMax = 12, weekNumber, weightStep = 2.5, } = params;
    const suggestions = [];
    for (let reps = repMin; reps <= repMax; reps++) {
        // Raw weight to exactly hit the target volume
        const rawWeight = calcWeight(targetVolume, fixedSeries, reps);
        // Round UP to ensure we never go below target (conservative rounding)
        const roundedWeight = roundToNearest(rawWeight, weightStep);
        // Ensure minimum weight
        if (roundedWeight <= 0)
            continue;
        const actualVolume = calcVolume(fixedSeries, reps, roundedWeight);
        // Core rule: new volume must be >= previous volume
        if (actualVolume >= prevVolume) {
            suggestions.push({
                series: fixedSeries,
                reps,
                weight: roundedWeight,
                volume: actualVolume,
                weekNumber,
            });
        }
    }
    // Sort by volume ascending so the user sees the smallest valid increment first
    suggestions.sort((a, b) => a.volume - b.volume);
    return suggestions;
}
//# sourceMappingURL=volumeEngine.js.map
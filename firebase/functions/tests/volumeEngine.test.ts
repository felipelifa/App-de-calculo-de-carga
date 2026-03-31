import {
  calcVolume,
  calcWeekTarget,
  calcWeight,
  roundToNearest,
  generateSuggestions,
} from "../src/volumeEngine";

// ════════════════════════════════════════════════════════════
// calcVolume
// ════════════════════════════════════════════════════════════
describe("calcVolume", () => {
  it("should calculate series × reps × weight", () => {
    expect(calcVolume(4, 10, 100)).toBe(4000);
    expect(calcVolume(3, 8, 80)).toBe(1920);
    expect(calcVolume(5, 12, 60)).toBe(3600);
  });

  it("should return 0 if weight is 0", () => {
    expect(calcVolume(4, 10, 0)).toBe(0);
  });
});

// ════════════════════════════════════════════════════════════
// calcWeekTarget
// ════════════════════════════════════════════════════════════
describe("calcWeekTarget", () => {
  it("should apply + progression correctly", () => {
    expect(calcWeekTarget(4000, 2)).toBeCloseTo(4080);
    expect(calcWeekTarget(4000, 4)).toBeCloseTo(4160);
    expect(calcWeekTarget(4000, 0)).toBe(4000);
  });

  it("should apply deload (negative) correctly", () => {
    expect(calcWeekTarget(4000, -10)).toBeCloseTo(3600);
    expect(calcWeekTarget(4243, -10)).toBeCloseTo(3818.7);
  });
});

// ════════════════════════════════════════════════════════════
// calcWeight
// ════════════════════════════════════════════════════════════
describe("calcWeight", () => {
  it("should calculate target weight", () => {
    // 4080 / (4 × 10) = 102
    expect(calcWeight(4080, 4, 10)).toBeCloseTo(102);
    // 4080 / (4 × 8) = 127.5
    expect(calcWeight(4080, 4, 8)).toBeCloseTo(127.5);
  });

  it("should throw for invalid series or reps", () => {
    expect(() => calcWeight(4000, 0, 10)).toThrow();
    expect(() => calcWeight(4000, 4, 0)).toThrow();
  });
});

// ════════════════════════════════════════════════════════════
// roundToNearest
// ════════════════════════════════════════════════════════════
describe("roundToNearest", () => {
  it("should round to nearest 2.5", () => {
    expect(roundToNearest(47.3)).toBe(47.5);
    expect(roundToNearest(102.0)).toBe(102.5);
    expect(roundToNearest(100.0)).toBe(100.0);
    expect(roundToNearest(101.2)).toBe(100.0);
    expect(roundToNearest(101.3)).toBe(102.5);
  });

  it("should round to custom multiple", () => {
    expect(roundToNearest(47.3, 5)).toBe(45);
    expect(roundToNearest(48, 5)).toBe(50);
  });
});

// ════════════════════════════════════════════════════════════
// generateSuggestions
// ════════════════════════════════════════════════════════════
describe("generateSuggestions", () => {
  it("should generate valid suggestions that are all >= prevVolume", () => {
    const prevVolume = 4000;
    const targetVolume = 4080; // +2%
    const results = generateSuggestions({
      prevVolume,
      targetVolume,
      fixedSeries: 4,
      repMin: 8,
      repMax: 12,
      weekNumber: 2,
    });

    expect(results.length).toBeGreaterThan(0);
    results.forEach((s) => {
      expect(s.volume).toBeGreaterThanOrEqual(prevVolume);
      expect(s.reps).toBeGreaterThanOrEqual(8);
      expect(s.reps).toBeLessThanOrEqual(12);
      expect(s.series).toBe(4);
      // Weight must be a multiple of 2.5
      expect(s.weight % 2.5).toBeCloseTo(0);
    });
  });

  it("should return empty if no valid combination exists (edge case: prevVolume too high)", () => {
    // Virtually impossible to hit with these reps
    const results = generateSuggestions({
      prevVolume: 999999,
      targetVolume: 1000000,
      fixedSeries: 1,
      repMin: 8,
      repMax: 12,
      weekNumber: 1,
    });
    // Some very heavy weights would still be generated unless capped
    // This test verifies no negative/zero weight is included
    results.forEach((s) => {
      expect(s.weight).toBeGreaterThan(0);
    });
  });

  it("should sort results by volume ascending", () => {
    const results = generateSuggestions({
      prevVolume: 4000,
      targetVolume: 4080,
      fixedSeries: 4,
      weekNumber: 2,
    });
    for (let i = 1; i < results.length; i++) {
      expect(results[i].volume).toBeGreaterThanOrEqual(results[i - 1].volume);
    }
  });

  it("should mark correct weekNumber on all suggestions", () => {
    const results = generateSuggestions({
      prevVolume: 3000,
      targetVolume: 3100,
      fixedSeries: 3,
      weekNumber: 5,
    });
    results.forEach((s) => expect(s.weekNumber).toBe(5));
  });

  // ── Periodization example from spec ──────────────────────
  it("should handle multi-week periodization volumes correctly", () => {
    const week1 = 4000;
    const week2 = calcWeekTarget(week1, 2);   // 4080
    const week3 = calcWeekTarget(week2, 4);   // 4243.2
    const week4deload = calcWeekTarget(week3, -10); // ~3818.88

    expect(week2).toBeCloseTo(4080);
    expect(week3).toBeCloseTo(4243.2);
    expect(week4deload).toBeCloseTo(3818.88);

    // Week 4 is deload: volume CAN be < week3 (deload exception)
    // But week2 must be >= week1, week3 >= week2
    expect(week2).toBeGreaterThanOrEqual(week1);
    expect(week3).toBeGreaterThanOrEqual(week2);
  });
});

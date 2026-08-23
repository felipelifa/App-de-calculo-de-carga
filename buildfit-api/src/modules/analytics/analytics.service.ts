import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  async getWeeklyVolume(userId: string, weeks: number = 12) {
    const results: { weekNumber: number; totalVolume: number; workoutCount: number }[] = [];
    const now = new Date();

    for (let i = 0; i < weeks; i++) {
      const weekDate = new Date(now);
      weekDate.setDate(weekDate.getDate() - i * 7);
      const weekNumber = this.getWeekNumber(weekDate);

      const aggregate = await this.prisma.workout.aggregate({
        where: { userId, weekNumber },
        _sum: { totalVolume: true },
        _count: true,
      });

      results.unshift({
        weekNumber,
        totalVolume: aggregate._sum.totalVolume || 0,
        workoutCount: aggregate._count,
      });
    }

    return results;
  }

  async getMuscleVolume(userId: string, period: 'week' | 'month' = 'week') {
    const now = new Date();
    let startDate: Date;

    if (period === 'week') {
      startDate = new Date(now);
      startDate.setDate(now.getDate() - 7);
    } else {
      startDate = new Date(now);
      startDate.setMonth(now.getMonth() - 1);
    }

    const workouts = await this.prisma.workout.findMany({
      where: {
        userId,
        date: { gte: startDate },
      },
      include: {
        exercises: {
          include: { sets: true },
        },
      },
    });

    const muscleVolume: Record<string, number> = {};

    workouts.forEach((w) => {
      w.exercises.forEach((ex) => {
        const muscle = ex.muscleGroup || 'outro';
        const exVolume = ex.sets.reduce((sum, set) => sum + set.volume, 0);
        muscleVolume[muscle] = (muscleVolume[muscle] || 0) + exVolume;
      });
    });

    return Object.entries(muscleVolume)
      .map(([muscle, volume]) => ({ muscle, volume }))
      .sort((a, b) => b.volume - a.volume);
  }

  async getExerciseProgress(userId: string, exerciseId: string, limit: number = 20) {
    const workouts = await this.prisma.workout.findMany({
      where: { userId },
      include: {
        exercises: {
          where: { exerciseId },
          include: { sets: true },
        },
      },
      orderBy: { date: 'desc' },
      take: limit,
    });

    return workouts
      .filter((w) => w.exercises.length > 0)
      .map((w) => {
        const ex = w.exercises[0];
        const maxWeight = Math.max(...ex.sets.map((s) => s.weight));
        const totalVolume = ex.sets.reduce((sum, s) => sum + s.volume, 0);

        return {
          date: w.date,
          maxWeight,
          totalVolume,
          sets: ex.sets.length,
          reps: ex.sets.reduce((sum, s) => sum + s.reps, 0),
        };
      })
      .reverse();
  }

  async getDashboard(userId: string) {
    const currentWeek = this.getWeekNumber(new Date());
    const lastWeek = currentWeek - 1;

    const [currentWeekData, lastWeekData, totalWorkouts, totalPRs] = await Promise.all([
      this.prisma.workout.aggregate({
        where: { userId, weekNumber: currentWeek },
        _sum: { totalVolume: true },
        _count: true,
      }),
      this.prisma.workout.aggregate({
        where: { userId, weekNumber: lastWeek },
        _sum: { totalVolume: true },
        _count: true,
      }),
      this.prisma.workout.count({ where: { userId } }),
      this.prisma.personalRecord.count({ where: { userId } }),
    ]);

    const currentVolume = currentWeekData._sum.totalVolume || 0;
    const lastVolume = lastWeekData._sum.totalVolume || 0;
    const volumeChange = lastVolume > 0
      ? ((currentVolume - lastVolume) / lastVolume) * 100
      : 0;

    return {
      currentWeek: {
        volume: currentVolume,
        workouts: currentWeekData._count,
      },
      lastWeek: {
        volume: lastVolume,
        workouts: lastWeekData._count,
      },
      volumeChangePercent: Math.round(volumeChange * 100) / 100,
      totalWorkouts,
      totalPRs,
    };
  }

  private getWeekNumber(date: Date): number {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    return Math.ceil(((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
  }
}

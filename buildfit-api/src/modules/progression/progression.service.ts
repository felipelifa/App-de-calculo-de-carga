import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';

@Injectable()
export class ProgressionService {
  constructor(private prisma: PrismaService) {}

  async getState(userId: string) {
    return this.prisma.progressionState.findUnique({
      where: { userId },
    });
  }

  async updateState(userId: string, data: any) {
    return this.prisma.progressionState.upsert({
      where: { userId },
      update: {
        phase: data.phase,
        currentWeek: data.currentWeek,
        isDeloadWeek: data.isDeloadWeek,
        exerciseStates: data.exerciseStates,
      },
      create: {
        userId,
        phase: data.phase || 'normal',
        currentWeek: data.currentWeek || 1,
        isDeloadWeek: data.isDeloadWeek || false,
        exerciseStates: data.exerciseStates || {},
      },
    });
  }

  async getSuggestions(userId: string, exerciseId?: string) {
    const where: any = { userId };
    if (exerciseId) where.exerciseId = exerciseId;

    return this.prisma.suggestedProgression.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async saveSuggestions(userId: string, suggestions: any[]) {
    await this.prisma.suggestedProgression.deleteMany({
      where: { userId },
    });

    return this.prisma.suggestedProgression.createMany({
      data: suggestions.map((s) => ({
        userId,
        exerciseId: s.exerciseId,
        weekNumber: s.weekNumber,
        series: s.series,
        reps: s.reps,
        weight: s.weight,
        volume: s.volume,
      })),
    });
  }

  async getVolumeHistory(userId: string, exerciseId: string) {
    return this.prisma.volumeHistory.findMany({
      where: { userId, exerciseId },
      orderBy: { weekNumber: 'asc' },
    });
  }

  async saveVolumeHistory(userId: string, data: any) {
    return this.prisma.volumeHistory.create({
      data: {
        userId,
        exerciseId: data.exerciseId,
        weekNumber: data.weekNumber,
        totalVolume: data.totalVolume,
      },
    });
  }
}

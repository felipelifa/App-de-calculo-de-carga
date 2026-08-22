import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';

@Injectable()
export class PrService {
  constructor(private prisma: PrismaService) {}

  async getAll(userId: string) {
    return this.prisma.personalRecord.findMany({
      where: { userId },
      orderBy: { achievedAt: 'desc' },
    });
  }

  async getForExercise(userId: string, exerciseId: string) {
    return this.prisma.personalRecord.findUnique({
      where: { userId_exerciseId: { userId, exerciseId } },
    });
  }

  async checkAndUpdate(userId: string, exerciseId: string, exerciseName: string, muscleGroup: string, weight: number, reps: number) {
    const volume = weight * reps;

    const existing = await this.prisma.personalRecord.findUnique({
      where: { userId_exerciseId: { userId, exerciseId } },
    });

    if (!existing) {
      return this.prisma.personalRecord.create({
        data: {
          userId,
          exerciseId,
          exerciseName,
          muscleGroup,
          maxWeight: weight,
          maxReps: reps,
          maxVolume: volume,
        },
      });
    }

    const updates: any = {};
    let isNewPR = false;

    if (weight > existing.maxWeight) {
      updates.maxWeight = weight;
      isNewPR = true;
    }
    if (volume > existing.maxVolume) {
      updates.maxVolume = volume;
      isNewPR = true;
    }
    if (reps > existing.maxReps && weight >= existing.maxWeight) {
      updates.maxReps = reps;
      isNewPR = true;
    }

    if (isNewPR) {
      updates.achievedAt = new Date();
      return this.prisma.personalRecord.update({
        where: { id: existing.id },
        data: updates,
      });
    }

    return existing;
  }

  async getRecentPRs(userId: string, limit: number = 10) {
    return this.prisma.personalRecord.findMany({
      where: { userId },
      orderBy: { achievedAt: 'desc' },
      take: limit,
    });
  }
}

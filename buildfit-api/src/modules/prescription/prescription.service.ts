import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';

@Injectable()
export class PrescriptionService {
  constructor(private prisma: PrismaService) {}

  async getActiveWorkout(userId: string) {
    return this.prisma.generatedWorkout.findFirst({
      where: { userId, isActive: true },
    });
  }

  async getAllWorkouts(userId: string) {
    return this.prisma.generatedWorkout.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async saveWorkout(userId: string, data: any) {
    return this.prisma.$transaction(async (tx) => {
      const isActive = data.isActive === true;
      if (isActive) {
        await tx.generatedWorkout.updateMany({
          where: { userId, isActive: true },
          data: { isActive: false },
        });
      }

      return tx.generatedWorkout.create({
        data: {
          userId,
          name: data.name,
          splitType: data.splitType,
          periodizationModel: data.periodizationModel,
          mesocycleDurationWeeks: data.mesocycleDurationWeeks ?? 4,
          preferredStyle: data.preferredStyle,
          isActive,
          sessions: data.sessions,
        },
      });
    });
  }

  async activateWorkout(userId: string, workoutId: string) {
    return this.prisma.$transaction(async (tx) => {
      const workout = await tx.generatedWorkout.findFirst({
        where: { id: workoutId, userId },
      });
      if (!workout) throw new NotFoundException('Plano de treino não encontrado');

      await tx.generatedWorkout.updateMany({
        where: { userId, isActive: true, id: { not: workoutId } },
        data: { isActive: false },
      });

      const updated = await tx.generatedWorkout.updateMany({
        where: { id: workoutId, userId },
        data: { isActive: true },
      });
      if (updated.count !== 1) {
        throw new NotFoundException('Plano de treino não encontrado');
      }

      return tx.generatedWorkout.findUnique({ where: { id: workoutId } });
    });
  }

  async updateWorkout(userId: string, workoutId: string, data: any) {
    return this.prisma.$transaction(async (tx) => {
      const workout = await tx.generatedWorkout.findFirst({
        where: { id: workoutId, userId },
      });
      if (!workout) throw new NotFoundException('Plano de treino não encontrado');

      const isActive = data.isActive === true;
      if (isActive) {
        await tx.generatedWorkout.updateMany({
          where: { userId, isActive: true, id: { not: workoutId } },
          data: { isActive: false },
        });
      }

      const updated = await tx.generatedWorkout.updateMany({
        where: { id: workoutId, userId },
        data: {
          ...(data.name !== undefined && { name: data.name }),
          ...(data.splitType !== undefined && { splitType: data.splitType }),
          ...(data.periodizationModel !== undefined && {
            periodizationModel: data.periodizationModel,
          }),
          ...(data.mesocycleDurationWeeks !== undefined && {
            mesocycleDurationWeeks: data.mesocycleDurationWeeks,
          }),
          ...(data.preferredStyle !== undefined && { preferredStyle: data.preferredStyle }),
          ...(data.sessions !== undefined && { sessions: data.sessions }),
          ...(data.isActive !== undefined && { isActive }),
        },
      });
      if (updated.count !== 1) {
        throw new NotFoundException('Plano de treino não encontrado');
      }

      return tx.generatedWorkout.findUnique({ where: { id: workoutId } });
    });
  }

  async deleteWorkout(userId: string, workoutId: string) {
    const workout = await this.prisma.generatedWorkout.findFirst({
      where: { id: workoutId, userId },
    });
    if (!workout) throw new NotFoundException('Plano de treino não encontrado');

    const deleted = await this.prisma.generatedWorkout.deleteMany({
      where: { id: workoutId, userId },
    });
    if (deleted.count !== 1) {
      throw new NotFoundException('Plano de treino não encontrado');
    }

    return { success: true };
  }
}

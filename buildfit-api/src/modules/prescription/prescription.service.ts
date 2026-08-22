import { Injectable } from '@nestjs/common';
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
    if (data.isActive) {
      await this.prisma.generatedWorkout.updateMany({
        where: { userId, isActive: true },
        data: { isActive: false },
      });
    }

    return this.prisma.generatedWorkout.create({
      data: {
        userId,
        name: data.name,
        splitType: data.splitType,
        periodizationModel: data.periodizationModel,
        mesocycleDurationWeeks: data.mesocycleDurationWeeks || 4,
        isActive: data.isActive || false,
        sessions: data.sessions,
      },
    });
  }

  async activateWorkout(userId: string, workoutId: string) {
    await this.prisma.generatedWorkout.updateMany({
      where: { userId, isActive: true },
      data: { isActive: false },
    });

    return this.prisma.generatedWorkout.update({
      where: { id: workoutId },
      data: { isActive: true },
    });
  }

  async deleteWorkout(userId: string, workoutId: string) {
    return this.prisma.generatedWorkout.deleteMany({
      where: { id: workoutId, userId },
    });
  }
}

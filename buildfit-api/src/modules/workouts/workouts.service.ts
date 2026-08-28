import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';
import { CreateWorkoutDto } from './dto/create-workout.dto';
import { UpdateWorkoutDto } from './dto/update-workout.dto';

@Injectable()
export class WorkoutsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateWorkoutDto) {
    const weekNumber = this.getWeekNumber(new Date(dto.date || new Date()));

    const workout = await this.prisma.workout.create({
      data: {
        userId,
        date: dto.date ? new Date(dto.date) : new Date(),
        weekNumber,
        notes: dto.notes,
        durationMinutes: dto.durationMinutes,
        exercises: {
          create: dto.exercises.map((ex) => ({
            exerciseId: ex.exerciseId,
            exerciseName: ex.exerciseName,
            muscleGroup: ex.muscleGroup,
            rir: ex.rir,
            tempo: ex.tempo,
            notes: ex.notes,
            sets: {
              create: ex.sets.map((set) => ({
                setNumber: set.setNumber,
                reps: set.reps,
                weight: set.weight,
                volume: set.isWarmup ? 0 : set.reps * set.weight,
                isWarmup: set.isWarmup || false,
              })),
            },
          })),
        },
      },
      include: {
        exercises: {
          include: { sets: true },
        },
      },
    });

    const totalVolume = workout.exercises.reduce((total, ex) => {
      return total + ex.sets.reduce((setTotal, set) => setTotal + set.volume, 0);
    }, 0);

    await this.prisma.workout.update({
      where: { id: workout.id },
      data: {
        totalVolume,
        exerciseCount: workout.exercises.length,
      },
    });

    return { ...workout, totalVolume };
  }

  async findAll(userId: string, options?: { weekNumber?: number; limit?: number }) {
    const where: any = { userId };
    if (options?.weekNumber) {
      where.weekNumber = options.weekNumber;
    }

    return this.prisma.workout.findMany({
      where,
      include: {
        exercises: {
          include: { sets: true },
        },
      },
      orderBy: { date: 'desc' },
      take: options?.limit || 50,
    });
  }

  async findOne(id: string, userId: string) {
    const workout = await this.prisma.workout.findFirst({
      where: { id, userId },
      include: {
        exercises: {
          include: { sets: true },
        },
      },
    });

    if (!workout) throw new NotFoundException('Treino não encontrado');
    return workout;
  }

  async update(id: string, userId: string, dto: UpdateWorkoutDto) {
    const workout = await this.findOne(id, userId);

    if (dto.exercises) {
      await this.prisma.workoutExercise.deleteMany({
        where: { workoutId: id },
      });
    }

    const updated = await this.prisma.workout.update({
      where: { id },
      data: {
        notes: dto.notes,
        durationMinutes: dto.durationMinutes,
        exercises: dto.exercises
          ? {
              create: dto.exercises.map((ex) => ({
                exerciseId: ex.exerciseId,
                exerciseName: ex.exerciseName,
                muscleGroup: ex.muscleGroup,
                rir: ex.rir,
                tempo: ex.tempo,
                notes: ex.notes,
                sets: {
                  create: ex.sets.map((set) => ({
                    setNumber: set.setNumber,
                    reps: set.reps,
                    weight: set.weight,
                    volume: set.isWarmup ? 0 : set.reps * set.weight,
                    isWarmup: set.isWarmup || false,
                  })),
                },
              })),
            }
          : undefined,
      },
      include: {
        exercises: {
          include: { sets: true },
        },
      },
    });

    const totalVolume = updated.exercises.reduce((total, ex) => {
      return total + ex.sets.reduce((setTotal, set) => setTotal + set.volume, 0);
    }, 0);

    await this.prisma.workout.update({
      where: { id },
      data: { totalVolume, exerciseCount: updated.exercises.length },
    });

    return { ...updated, totalVolume };
  }

  async delete(id: string, userId: string) {
    const workout = await this.findOne(id, userId);
    return this.prisma.workout.delete({ where: { id } });
  }

  async getWeeklyVolume(userId: string, weekNumber?: number) {
    const week = weekNumber || this.getWeekNumber(new Date());

    const result = await this.prisma.workout.aggregate({
      where: { userId, weekNumber: week },
      _sum: { totalVolume: true },
      _count: true,
    });

    return {
      weekNumber: week,
      totalVolume: result._sum.totalVolume || 0,
      workoutCount: result._count,
    };
  }

  async getWeeklyMuscleVolume(userId: string, weekNumber?: number) {
    const week = weekNumber || this.getWeekNumber(new Date());

    const workouts = await this.prisma.workout.findMany({
      where: { userId, weekNumber: week },
      include: {
        exercises: {
          include: { sets: true },
        },
      },
    });

    const muscleVolume: Record<string, number> = {};

    workouts.forEach((w) => {
      w.exercises.forEach((ex) => {
        const muscle = ex.muscleGroup || 'unknown';
        const exVolume = ex.sets.reduce(
          (sum, set) => sum + (set.isWarmup ? 0 : set.volume),
          0,
        );
        muscleVolume[muscle] = (muscleVolume[muscle] || 0) + exVolume;
      });
    });

    return Object.entries(muscleVolume)
      .map(([muscle, volume]) => ({ muscle, volume }))
      .sort((a, b) => b.volume - a.volume);
  }

  private getWeekNumber(date: Date): number {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    return Math.ceil(((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
  }
}

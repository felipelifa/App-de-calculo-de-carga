import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { ExerciseFilterDto } from './dto/exercise-filter.dto';

@Injectable()
export class ExercisesService {
  constructor(private prisma: PrismaService) {}

  async findAll(filters: ExerciseFilterDto) {
    const where: any = {};

    if (filters.muscle) {
      where.primaryMuscles = { has: filters.muscle };
    }
    if (filters.equipment) {
      where.equipment = { has: filters.equipment };
    }
    if (filters.category) {
      where.category = filters.category;
    }
    if (filters.difficulty) {
      where.difficulty = filters.difficulty;
    }
    if (filters.movementPattern) {
      where.movementPattern = filters.movementPattern;
    }
    if (filters.search) {
      where.OR = [
        { name: { contains: filters.search, mode: 'insensitive' } },
        { nameEn: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const page = filters.page || 1;
    const limit = Math.min(filters.limit || 50, 100);
    const skip = (page - 1) * limit;

    const [exercises, total] = await Promise.all([
      this.prisma.exercise.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: 'asc' },
      }),
      this.prisma.exercise.count({ where }),
    ]);

    return {
      data: exercises,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOne(id: string) {
    const exercise = await this.prisma.exercise.findUnique({
      where: { id },
    });

    if (!exercise) {
      throw new NotFoundException(`Exercício '${id}' não encontrado`);
    }

    return exercise;
  }

  async findByMuscle(muscle: string) {
    return this.prisma.exercise.findMany({
      where: {
        OR: [
          { primaryMuscles: { has: muscle } },
          { secondaryMuscles: { has: muscle } },
        ],
      },
      orderBy: { name: 'asc' },
    });
  }

  async findSubstitutes(exerciseId: string) {
    const exercise = await this.findOne(exerciseId);
    const substitutes = await this.prisma.exercise.findMany({
      where: {
        id: { in: exercise.substituteIds },
      },
    });
    return substitutes;
  }

  async getMuscles() {
    const result = await this.prisma.exercise.findMany({
      select: { primaryMuscles: true },
    });

    const muscleSet = new Set<string>();
    result.forEach((e) => e.primaryMuscles.forEach((m) => muscleSet.add(m)));
    return Array.from(muscleSet).sort();
  }

  async getMovementPatterns() {
    const result = await this.prisma.exercise.findMany({
      select: { movementPattern: true },
      distinct: ['movementPattern'],
    });
    return result.map((r) => r.movementPattern).sort();
  }

  async create(dto: CreateExerciseDto) {
    return this.prisma.exercise.create({
      data: dto,
    });
  }

  async count() {
    return this.prisma.exercise.count();
  }
}

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';

@Injectable()
export class NutritionService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    return this.prisma.nutritionProfile.findUnique({
      where: { userId },
    });
  }

  async updateProfile(userId: string, data: any) {
    return this.prisma.nutritionProfile.upsert({
      where: { userId },
      update: data,
      create: { userId, ...data },
    });
  }

  async getDailyLog(userId: string, date: string) {
    const logDate = new Date(date);

    return this.prisma.nutritionDay.findUnique({
      where: { userId_date: { userId, date: logDate } },
      include: { meals: true },
    });
  }

  async logMeal(userId: string, date: string, meal: any) {
    const logDate = new Date(date);

    const day = await this.prisma.nutritionDay.upsert({
      where: { userId_date: { userId, date: logDate } },
      update: {},
      create: {
        userId,
        date: logDate,
      },
    });

    const entry = await this.prisma.mealEntry.create({
      data: {
        dayId: day.id,
        foodId: meal.foodId,
        foodName: meal.foodName,
        portionG: meal.portionG,
        calories: meal.calories,
        protein: meal.protein,
        carb: meal.carb,
        fat: meal.fat,
        mealType: meal.mealType,
        isCheatMeal: meal.isCheatMeal || false,
      },
    });

    await this.updateDayTotals(day.id);

    return entry;
  }

  async deleteMeal(userId: string, mealId: string) {
    const meal = await this.prisma.mealEntry.findUnique({
      where: { id: mealId },
      include: { day: true },
    });

    if (!meal || meal.day.userId !== userId) {
      throw new Error('Refeição não encontrada');
    }

    await this.prisma.mealEntry.delete({ where: { id: mealId } });
    await this.updateDayTotals(meal.dayId);

    return { success: true };
  }

  async getWeeklyLog(userId: string, startDate: string) {
    const start = new Date(startDate);
    const end = new Date(start);
    end.setDate(end.getDate() + 7);

    return this.prisma.nutritionDay.findMany({
      where: {
        userId,
        date: { gte: start, lt: end },
      },
      include: { meals: true },
      orderBy: { date: 'asc' },
    });
  }

  private async updateDayTotals(dayId: string) {
    const meals = await this.prisma.mealEntry.findMany({
      where: { dayId },
    });

    const totals = meals.reduce(
      (acc, meal) => ({
        calories: acc.calories + meal.calories,
        protein: acc.protein + meal.protein,
        carb: acc.carb + meal.carb,
        fat: acc.fat + meal.fat,
      }),
      { calories: 0, protein: 0, carb: 0, fat: 0 },
    );

    await this.prisma.nutritionDay.update({
      where: { id: dayId },
      data: {
        totalCalories: totals.calories,
        totalProtein: totals.protein,
        totalCarb: totals.carb,
        totalFat: totals.fat,
      },
    });
  }
}

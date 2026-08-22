import { Controller, Get, Post, Put, Delete, Param, Query, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { NutritionService } from './nutrition.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('nutrition')
@Controller('nutrition')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class NutritionController {
  constructor(private nutritionService: NutritionService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Obter perfil nutricional' })
  async getProfile(@CurrentUser('uid') uid: string) {
    const user = await this.getUser(uid);
    return this.nutritionService.getProfile(user.id);
  }

  @Put('profile')
  @ApiOperation({ summary: 'Atualizar perfil nutricional' })
  async updateProfile(
    @CurrentUser('uid') uid: string,
    @Body() body: any,
  ) {
    const user = await this.getUser(uid);
    return this.nutritionService.updateProfile(user.id, body);
  }

  @Get('daily')
  @ApiOperation({ summary: 'Obter log nutricional do dia' })
  async getDailyLog(
    @CurrentUser('uid') uid: string,
    @Query('date') date: string,
  ) {
    const user = await this.getUser(uid);
    return this.nutritionService.getDailyLog(user.id, date);
  }

  @Post('log')
  @ApiOperation({ summary: 'Registrar refeição' })
  async logMeal(
    @CurrentUser('uid') uid: string,
    @Body() body: any,
  ) {
    const user = await this.getUser(uid);
    return this.nutritionService.logMeal(user.id, body.date, body.meal);
  }

  @Delete('log/:mealId')
  @ApiOperation({ summary: 'Deletar refeição' })
  async deleteMeal(
    @Param('mealId') mealId: string,
    @CurrentUser('uid') uid: string,
  ) {
    const user = await this.getUser(uid);
    return this.nutritionService.deleteMeal(user.id, mealId);
  }

  @Get('weekly')
  @ApiOperation({ summary: 'Log nutricional semanal' })
  async getWeeklyLog(
    @CurrentUser('uid') uid: string,
    @Query('startDate') startDate: string,
  ) {
    const user = await this.getUser(uid);
    return this.nutritionService.getWeeklyLog(user.id, startDate);
  }

  private async getUser(uid: string) {
    const { PrismaService } = await import('../../common/services/prisma.service');
    const prisma = new PrismaService();
    await prisma.onModuleInit();
    const user = await prisma.user.findUnique({ where: { firebaseUid: uid } });
    await prisma.onModuleDestroy();
    if (!user) throw new Error('User not found');
    return user;
  }
}

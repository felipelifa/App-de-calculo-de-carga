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
  async getProfile(@CurrentUser('id') userId: string) {
    return this.nutritionService.getProfile(userId);
  }

  @Put('profile')
  @ApiOperation({ summary: 'Atualizar perfil nutricional' })
  async updateProfile(
    @CurrentUser('id') userId: string,
    @Body() body: any,
  ) {
    return this.nutritionService.updateProfile(userId, body);
  }

  @Get('daily')
  @ApiOperation({ summary: 'Obter log nutricional do dia' })
  async getDailyLog(
    @CurrentUser('id') userId: string,
    @Query('date') date: string,
  ) {
    return this.nutritionService.getDailyLog(userId, date);
  }

  @Post('log')
  @ApiOperation({ summary: 'Registrar refeição' })
  async logMeal(
    @CurrentUser('id') userId: string,
    @Body() body: any,
  ) {
    return this.nutritionService.logMeal(userId, body.date, body.meal);
  }

  @Delete('log/:mealId')
  @ApiOperation({ summary: 'Deletar refeição' })
  async deleteMeal(
    @Param('mealId') mealId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.nutritionService.deleteMeal(userId, mealId);
  }

  @Get('weekly')
  @ApiOperation({ summary: 'Log nutricional semanal' })
  async getWeeklyLog(
    @CurrentUser('id') userId: string,
    @Query('startDate') startDate: string,
  ) {
    return this.nutritionService.getWeeklyLog(userId, startDate);
  }
}

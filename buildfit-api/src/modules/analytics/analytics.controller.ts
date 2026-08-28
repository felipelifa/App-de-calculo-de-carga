import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AnalyticsService } from './analytics.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';
import { ProGuard } from '../../common/guards/pro.guard';

@ApiTags('analytics')
@Controller('analytics')
@UseGuards(FirebaseAuthGuard, ProGuard)
@ApiBearerAuth()
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Dados do dashboard principal' })
  async getDashboard(@CurrentUser('id') userId: string) {
    return this.analyticsService.getDashboard(userId);
  }

  @Get('weekly-volume')
  @ApiOperation({ summary: 'Volume semanal ao longo do tempo' })
  @ApiQuery({ name: 'weeks', required: false, type: Number })
  async getWeeklyVolume(
    @CurrentUser('id') userId: string,
    @Query('weeks') weeks?: number,
  ) {
    return this.analyticsService.getWeeklyVolume(userId, weeks);
  }

  @Get('muscle-volume')
  @ApiOperation({ summary: 'Volume por grupo muscular' })
  @ApiQuery({ name: 'period', required: false, enum: ['week', 'month'] })
  async getMuscleVolume(
    @CurrentUser('id') userId: string,
    @Query('period') period?: 'week' | 'month',
  ) {
    return this.analyticsService.getMuscleVolume(userId, period);
  }

  @Get('exercise-progress')
  @ApiOperation({ summary: 'Progressão de carga de um exercício' })
  @ApiQuery({ name: 'exerciseId', required: true, type: String })
  async getExerciseProgress(
    @CurrentUser('id') userId: string,
    @Query('exerciseId') exerciseId: string,
  ) {
    return this.analyticsService.getExerciseProgress(userId, exerciseId);
  }
}

import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AnalyticsService } from './analytics.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('analytics')
@Controller('analytics')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Dados do dashboard principal' })
  async getDashboard(@CurrentUser('uid') uid: string) {
    const user = await this.getUser(uid);
    return this.analyticsService.getDashboard(user.id);
  }

  @Get('weekly-volume')
  @ApiOperation({ summary: 'Volume semanal ao longo do tempo' })
  @ApiQuery({ name: 'weeks', required: false, type: Number })
  async getWeeklyVolume(
    @CurrentUser('uid') uid: string,
    @Query('weeks') weeks?: number,
  ) {
    const user = await this.getUser(uid);
    return this.analyticsService.getWeeklyVolume(user.id, weeks);
  }

  @Get('muscle-volume')
  @ApiOperation({ summary: 'Volume por grupo muscular' })
  @ApiQuery({ name: 'period', required: false, enum: ['week', 'month'] })
  async getMuscleVolume(
    @CurrentUser('uid') uid: string,
    @Query('period') period?: 'week' | 'month',
  ) {
    const user = await this.getUser(uid);
    return this.analyticsService.getMuscleVolume(user.id, period);
  }

  @Get('exercise-progress')
  @ApiOperation({ summary: 'Progressão de carga de um exercício' })
  @ApiQuery({ name: 'exerciseId', required: true, type: String })
  async getExerciseProgress(
    @CurrentUser('uid') uid: string,
    @Query('exerciseId') exerciseId: string,
  ) {
    const user = await this.getUser(uid);
    return this.analyticsService.getExerciseProgress(user.id, exerciseId);
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

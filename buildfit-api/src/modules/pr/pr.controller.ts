import { Controller, Get, Post, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PrService } from './pr.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';
import { ProGuard } from '../../common/guards/pro.guard';

@ApiTags('pr')
@Controller('pr')
@UseGuards(FirebaseAuthGuard, ProGuard)
@ApiBearerAuth()
export class PrController {
  constructor(private prService: PrService) {}

  @Get()
  @ApiOperation({ summary: 'Listar todos os records pessoais' })
  async getAll(@CurrentUser('id') userId: string) {
    return this.prService.getAll(userId);
  }

  @Get(':exerciseId')
  @ApiOperation({ summary: 'Obter PR de um exercício específico' })
  async getForExercise(
    @Param('exerciseId') exerciseId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.prService.getForExercise(userId, exerciseId);
  }

  @Post('check')
  @ApiOperation({ summary: 'Verificar e atualizar PR após treino' })
  async checkPR(
    @CurrentUser('id') userId: string,
    @Body() body: {
      exerciseId: string;
      exerciseName: string;
      muscleGroup: string;
      weight: number;
      reps: number;
    },
  ) {
    return this.prService.checkAndUpdate(
      userId,
      body.exerciseId,
      body.exerciseName,
      body.muscleGroup,
      body.weight,
      body.reps,
    );
  }

  @Get('recent/list')
  @ApiOperation({ summary: 'PRs recentes' })
  async getRecent(
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
  ) {
    return this.prService.getRecentPRs(userId, limit);
  }
}

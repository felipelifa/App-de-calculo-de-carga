import { Controller, Get, Post, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PrService } from './pr.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('pr')
@Controller('pr')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class PrController {
  constructor(private prService: PrService) {}

  @Get()
  @ApiOperation({ summary: 'Listar todos os records pessoais' })
  async getAll(@CurrentUser('uid') uid: string) {
    const user = await this.getUser(uid);
    return this.prService.getAll(user.id);
  }

  @Get(':exerciseId')
  @ApiOperation({ summary: 'Obter PR de um exercício específico' })
  async getForExercise(
    @Param('exerciseId') exerciseId: string,
    @CurrentUser('uid') uid: string,
  ) {
    const user = await this.getUser(uid);
    return this.prService.getForExercise(user.id, exerciseId);
  }

  @Post('check')
  @ApiOperation({ summary: 'Verificar e atualizar PR após treino' })
  async checkPR(
    @CurrentUser('uid') uid: string,
    @Body() body: {
      exerciseId: string;
      exerciseName: string;
      muscleGroup: string;
      weight: number;
      reps: number;
    },
  ) {
    const user = await this.getUser(uid);
    return this.prService.checkAndUpdate(
      user.id,
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
    @CurrentUser('uid') uid: string,
    @Query('limit') limit?: number,
  ) {
    const user = await this.getUser(uid);
    return this.prService.getRecentPRs(user.id, limit);
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

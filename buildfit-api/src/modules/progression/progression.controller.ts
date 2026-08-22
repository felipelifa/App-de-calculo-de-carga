import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ProgressionService } from './progression.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('progression')
@Controller('progression')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class ProgressionController {
  constructor(private progressionService: ProgressionService) {}

  @Get('state')
  @ApiOperation({ summary: 'Obter estado de progressão' })
  async getState(@CurrentUser('uid') uid: string) {
    const user = await this.getUser(uid);
    return this.progressionService.getState(user.id);
  }

  @Put('state')
  @ApiOperation({ summary: 'Atualizar estado de progressão' })
  async updateState(
    @CurrentUser('uid') uid: string,
    @Body() body: any,
  ) {
    const user = await this.getUser(uid);
    return this.progressionService.updateState(user.id, body);
  }

  @Get('suggestions')
  @ApiOperation({ summary: 'Obter sugestões de progressão' })
  async getSuggestions(
    @CurrentUser('uid') uid: string,
    @Query('exerciseId') exerciseId?: string,
  ) {
    const user = await this.getUser(uid);
    return this.progressionService.getSuggestions(user.id, exerciseId);
  }

  @Post('suggestions')
  @ApiOperation({ summary: 'Salvar sugestões de progressão' })
  async saveSuggestions(
    @CurrentUser('uid') uid: string,
    @Body() body: { suggestions: any[] },
  ) {
    const user = await this.getUser(uid);
    return this.progressionService.saveSuggestions(user.id, body.suggestions);
  }

  @Get('volume-history')
  @ApiOperation({ summary: 'Histórico de volume por exercício' })
  async getVolumeHistory(
    @CurrentUser('uid') uid: string,
    @Query('exerciseId') exerciseId: string,
  ) {
    const user = await this.getUser(uid);
    return this.progressionService.getVolumeHistory(user.id, exerciseId);
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

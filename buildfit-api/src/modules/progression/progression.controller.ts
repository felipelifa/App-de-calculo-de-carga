import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ProgressionService } from './progression.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';
import { ProGuard } from '../../common/guards/pro.guard';

@ApiTags('progression')
@Controller('progression')
@UseGuards(FirebaseAuthGuard, ProGuard)
@ApiBearerAuth()
export class ProgressionController {
  constructor(private progressionService: ProgressionService) {}

  @Get('state')
  @ApiOperation({ summary: 'Obter estado de progressão' })
  async getState(@CurrentUser('id') userId: string) {
    return this.progressionService.getState(userId);
  }

  @Put('state')
  @ApiOperation({ summary: 'Atualizar estado de progressão' })
  async updateState(
    @CurrentUser('id') userId: string,
    @Body() body: any,
  ) {
    return this.progressionService.updateState(userId, body);
  }

  @Get('suggestions')
  @ApiOperation({ summary: 'Obter sugestões de progressão' })
  async getSuggestions(
    @CurrentUser('id') userId: string,
    @Query('exerciseId') exerciseId?: string,
  ) {
    return this.progressionService.getSuggestions(userId, exerciseId);
  }

  @Post('suggestions')
  @ApiOperation({ summary: 'Salvar sugestões de progressão' })
  async saveSuggestions(
    @CurrentUser('id') userId: string,
    @Body() body: { suggestions: any[] },
  ) {
    return this.progressionService.saveSuggestions(userId, body.suggestions);
  }

  @Get('volume-history')
  @ApiOperation({ summary: 'Histórico de volume por exercício' })
  async getVolumeHistory(
    @CurrentUser('id') userId: string,
    @Query('exerciseId') exerciseId: string,
  ) {
    return this.progressionService.getVolumeHistory(userId, exerciseId);
  }
}

import { Controller, Get, Post, Put, Delete, Param, Query, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { WorkoutsService } from './workouts.service';
import { CreateWorkoutDto } from './dto/create-workout.dto';
import { UpdateWorkoutDto } from './dto/update-workout.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('workouts')
@Controller('workouts')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class WorkoutsController {
  constructor(private workoutsService: WorkoutsService) {}

  @Post()
  @ApiOperation({ summary: 'Criar novo treino registrado' })
  async create(
    @CurrentUser('uid') uid: string,
    @Body() dto: CreateWorkoutDto,
  ) {
    return this.workoutsService.create(uid, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Listar treinos do usuário' })
  async findAll(
    @CurrentUser('uid') uid: string,
    @Query('week') week?: number,
    @Query('limit') limit?: number,
  ) {
    return this.workoutsService.findAll(uid, { weekNumber: week, limit });
  }

  @Get('weekly-volume')
  @ApiOperation({ summary: 'Volume semanal total' })
  async getWeeklyVolume(
    @CurrentUser('uid') uid: string,
    @Query('week') week?: number,
  ) {
    return this.workoutsService.getWeeklyVolume(uid, week);
  }

  @Get('muscle-volume')
  @ApiOperation({ summary: 'Volume por grupo muscular na semana' })
  async getMuscleVolume(
    @CurrentUser('uid') uid: string,
    @Query('week') week?: number,
  ) {
    return this.workoutsService.getWeeklyMuscleVolume(uid, week);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obter treino por ID' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser('uid') uid: string,
  ) {
    return this.workoutsService.findOne(id, uid);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Atualizar treino' })
  async update(
    @Param('id') id: string,
    @CurrentUser('uid') uid: string,
    @Body() dto: UpdateWorkoutDto,
  ) {
    return this.workoutsService.update(id, uid, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deletar treino' })
  async delete(
    @Param('id') id: string,
    @CurrentUser('uid') uid: string,
  ) {
    return this.workoutsService.delete(id, uid);
  }
}

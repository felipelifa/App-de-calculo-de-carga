import { Controller, Get, Post, Put, Delete, Param, Query, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { WorkoutsService } from './workouts.service';
import { CreateWorkoutDto } from './dto/create-workout.dto';
import { UpdateWorkoutDto } from './dto/update-workout.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('workouts')
@Controller('workouts')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class WorkoutsController {
  constructor(private workoutsService: WorkoutsService) {}

  @Post()
  @ApiOperation({ summary: 'Criar novo treino registrado' })
  async create(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateWorkoutDto,
  ) {
    return this.workoutsService.create(userId, dto);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Listar treinos do usuário' })
  async findAll(
    @CurrentUser('id') userId: string,
    @Query('week') week?: number,
    @Query('limit') limit?: number,
  ) {
    return this.workoutsService.findAll(userId, { weekNumber: week, limit });
  }

  @Get('weekly-volume')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Volume semanal total' })
  async getWeeklyVolume(
    @CurrentUser('id') userId: string,
    @Query('week') week?: number,
  ) {
    return this.workoutsService.getWeeklyVolume(userId, week);
  }

  @Get('muscle-volume')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Volume por grupo muscular na semana' })
  async getMuscleVolume(
    @CurrentUser('id') userId: string,
    @Query('week') week?: number,
  ) {
    return this.workoutsService.getWeeklyMuscleVolume(userId, week);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Obter treino por ID' })
  async findOne(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.workoutsService.findOne(id, userId);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Atualizar treino' })
  async update(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateWorkoutDto,
  ) {
    return this.workoutsService.update(id, userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deletar treino' })
  async delete(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.workoutsService.delete(id, userId);
  }
}

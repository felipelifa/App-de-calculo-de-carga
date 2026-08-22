import { Controller, Get, Post, Param, Query, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ExercisesService } from './exercises.service';
import { ExerciseFilterDto } from './dto/exercise-filter.dto';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('exercises')
@Controller('exercises')
export class ExercisesController {
  constructor(private exercisesService: ExercisesService) {}

  @Get()
  @ApiOperation({ summary: 'Listar exercícios com filtros' })
  async findAll(@Query() filters: ExerciseFilterDto) {
    return this.exercisesService.findAll(filters);
  }

  @Get('muscles')
  @ApiOperation({ summary: 'Listar grupos musculares disponíveis' })
  async getMuscles() {
    return this.exercisesService.getMuscles();
  }

  @Get('patterns')
  @ApiOperation({ summary: 'Listar padrões de movimento disponíveis' })
  async getPatterns() {
    return this.exercisesService.getMovementPatterns();
  }

  @Get('count')
  @ApiOperation({ summary: 'Contar total de exercícios' })
  async count() {
    const total = await this.exercisesService.count();
    return { total };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obter exercício por ID' })
  async findOne(@Param('id') id: string) {
    return this.exercisesService.findOne(id);
  }

  @Get(':id/substitutes')
  @ApiOperation({ summary: 'Obter substitutos de um exercício' })
  async findSubstitutes(@Param('id') id: string) {
    return this.exercisesService.findSubstitutes(id);
  }

  @Post()
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Criar exercício personalizado' })
  async create(@Body() dto: CreateExerciseDto) {
    return this.exercisesService.create(dto);
  }
}

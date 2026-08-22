import { IsString, IsOptional, IsNumber, IsArray, ValidateNested, IsDateString } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class WorkoutSetDto {
  @ApiProperty({ example: 1 })
  @IsNumber()
  setNumber: number;

  @ApiProperty({ example: 10 })
  @IsNumber()
  reps: number;

  @ApiProperty({ example: 80 })
  @IsNumber()
  weight: number;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  isWarmup?: boolean;
}

export class WorkoutExerciseDto {
  @ApiProperty({ example: 'agachamento_livre' })
  @IsString()
  exerciseId: string;

  @ApiProperty({ example: 'Agachamento Livre' })
  @IsString()
  exerciseName: string;

  @ApiPropertyOptional({ example: 'quads' })
  @IsOptional()
  @IsString()
  muscleGroup?: string;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @IsNumber()
  rir?: number;

  @ApiPropertyOptional({ example: '2-0-2' })
  @IsOptional()
  @IsString()
  tempo?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ type: [WorkoutSetDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => WorkoutSetDto)
  sets: WorkoutSetDto[];
}

export class CreateWorkoutDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  durationMinutes?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ type: [WorkoutExerciseDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => WorkoutExerciseDto)
  exercises: WorkoutExerciseDto[];
}

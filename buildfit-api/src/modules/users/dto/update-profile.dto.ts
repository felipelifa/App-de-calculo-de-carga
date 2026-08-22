import { IsOptional, IsString, IsNumber, IsArray, Min, Max } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 25 })
  @IsOptional()
  @IsNumber()
  @Min(10)
  @Max(100)
  age?: number;

  @ApiPropertyOptional({ example: 'male' })
  @IsOptional()
  @IsString()
  biologicalSex?: string;

  @ApiPropertyOptional({ example: 80.5 })
  @IsOptional()
  @IsNumber()
  @Min(30)
  @Max(300)
  weightKg?: number;

  @ApiPropertyOptional({ example: 175 })
  @IsOptional()
  @IsNumber()
  @Min(100)
  @Max(250)
  heightCm?: number;

  @ApiPropertyOptional({ example: 'intermediate' })
  @IsOptional()
  @IsString()
  experienceLevel?: string;

  @ApiPropertyOptional({ example: 24 })
  @IsOptional()
  @IsNumber()
  trainingAge?: number;

  @ApiPropertyOptional({ example: 'hypertrophy' })
  @IsOptional()
  @IsString()
  primaryGoal?: string;

  @ApiPropertyOptional({ example: 'full_gym' })
  @IsOptional()
  @IsString()
  environment?: string;

  @ApiPropertyOptional({ example: ['barbell', 'dumbbell', 'rack'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  availableEquipment?: string[];

  @ApiPropertyOptional({ example: ['knee', 'lower_back'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  healthRestrictions?: string[];

  @ApiPropertyOptional({ example: 4 })
  @IsOptional()
  @IsNumber()
  @Min(2)
  @Max(7)
  availableDaysPerWeek?: number;

  @ApiPropertyOptional({ example: 60 })
  @IsOptional()
  @IsNumber()
  sessionDurationMinutes?: number;

  @ApiPropertyOptional({ example: ['chest', 'biceps'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  priorityMuscles?: string[];
}

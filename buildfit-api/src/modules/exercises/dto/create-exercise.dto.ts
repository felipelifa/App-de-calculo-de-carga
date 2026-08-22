import { IsString, IsArray, IsOptional, IsNumber, IsBoolean, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateExerciseDto {
  @ApiProperty({ example: 'agachamento_livre' })
  @IsString()
  id: string;

  @ApiProperty({ example: 'Agachamento Livre' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Barbell Back Squat' })
  @IsOptional()
  @IsString()
  nameEn?: string;

  @ApiProperty({ example: ['quads', 'glutes'] })
  @IsArray()
  @IsString({ each: true })
  primaryMuscles: string[];

  @ApiPropertyOptional({ example: ['hamstrings', 'core'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  secondaryMuscles?: string[];

  @ApiProperty({ example: 'squat' })
  @IsString()
  movementPattern: string;

  @ApiProperty({ example: ['barbell', 'rack'] })
  @IsArray()
  @IsString({ each: true })
  equipment: string[];

  @ApiProperty({ example: ['gym'] })
  @IsArray()
  @IsString({ each: true })
  environment: string[];

  @ApiProperty({ example: 'compound' })
  @IsString()
  category: string;

  @ApiProperty({ example: 'intermediate' })
  @IsString()
  difficulty: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  restrictions?: string[];

  @ApiPropertyOptional({ example: 8 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(30)
  repRangeMin?: number;

  @ApiPropertyOptional({ example: 12 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(50)
  repRangeMax?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isUnilateral?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  gifUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  videoUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  cues?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  instructions?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  substituteIds?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  progressionIds?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  regressionIds?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ example: 0.7 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1)
  spinalLoad?: number;

  @ApiPropertyOptional({ example: 0.3 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1)
  shoulderStress?: number;

  @ApiPropertyOptional({ example: 0.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1)
  kneeStress?: number;

  @ApiPropertyOptional({ example: 0.8 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(1)
  cnsLoad?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stabilityType?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  lengthBias?: string;

  @ApiPropertyOptional({ example: 3 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(5)
  skillLevel?: number;
}

import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';

export class ExerciseFilterDto {
  @ApiPropertyOptional({ description: 'Busca por nome' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ description: 'Filtrar por músculo primário' })
  @IsOptional()
  @IsString()
  muscle?: string;

  @ApiPropertyOptional({ description: 'Filtrar por equipamento' })
  @IsOptional()
  @IsString()
  equipment?: string;

  @ApiPropertyOptional({ description: 'Filtrar por categoria (compound/isolation)' })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({ description: 'Filtrar por dificuldade (beginner/intermediate/advanced)' })
  @IsOptional()
  @IsString()
  difficulty?: string;

  @ApiPropertyOptional({ description: 'Filtrar por padrão de movimento' })
  @IsOptional()
  @IsString()
  movementPattern?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  page?: number;

  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Type(() => Number)
  limit?: number;
}

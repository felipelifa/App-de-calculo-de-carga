import { Module } from '@nestjs/common';
import { NutritionController } from './nutrition.controller';
import { NutritionService } from './nutrition.service';
import { CommonModule } from '../../common/common.module';

@Module({
  imports: [CommonModule],
  controllers: [NutritionController],
  providers: [NutritionService],
  exports: [NutritionService],
})
export class NutritionModule {}

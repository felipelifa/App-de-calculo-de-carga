import { Module } from '@nestjs/common';
import { NutritionController } from './nutrition.controller';
import { NutritionService } from './nutrition.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [NutritionController],
  providers: [NutritionService, PrismaService, FirebaseService],
  exports: [NutritionService],
})
export class NutritionModule {}

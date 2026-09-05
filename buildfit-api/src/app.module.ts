import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HealthController } from './common/controllers/health.controller';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ExercisesModule } from './modules/exercises/exercises.module';
import { WorkoutsModule } from './modules/workouts/workouts.module';
import { PrescriptionModule } from './modules/prescription/prescription.module';
import { ProgressionModule } from './modules/progression/progression.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { NutritionModule } from './modules/nutrition/nutrition.module';
import { PrModule } from './modules/pr/pr.module';
import { ProModule } from './modules/pro/pro.module';
import { CommonModule } from './common/common.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    CommonModule,
    AuthModule,
    UsersModule,
    ExercisesModule,
    WorkoutsModule,
    PrescriptionModule,
    ProgressionModule,
    AnalyticsModule,
    NutritionModule,
    PrModule,
    ProModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}

import { Module } from '@nestjs/common';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [AnalyticsController],
  providers: [AnalyticsService, PrismaService, FirebaseService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}

import { Module } from '@nestjs/common';
import { WorkoutsController } from './workouts.controller';
import { WorkoutsService } from './workouts.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [WorkoutsController],
  providers: [WorkoutsService, PrismaService, FirebaseService],
  exports: [WorkoutsService],
})
export class WorkoutsModule {}

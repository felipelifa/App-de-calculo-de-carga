import { Module } from '@nestjs/common';
import { ExercisesController } from './exercises.controller';
import { ExercisesService } from './exercises.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [ExercisesController],
  providers: [ExercisesService, PrismaService, FirebaseService],
  exports: [ExercisesService],
})
export class ExercisesModule {}

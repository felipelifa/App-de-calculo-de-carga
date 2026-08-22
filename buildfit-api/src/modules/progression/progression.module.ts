import { Module } from '@nestjs/common';
import { ProgressionController } from './progression.controller';
import { ProgressionService } from './progression.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [ProgressionController],
  providers: [ProgressionService, PrismaService, FirebaseService],
  exports: [ProgressionService],
})
export class ProgressionModule {}

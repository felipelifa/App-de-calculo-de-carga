import { Module } from '@nestjs/common';
import { PrescriptionController } from './prescription.controller';
import { PrescriptionService } from './prescription.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [PrescriptionController],
  providers: [PrescriptionService, PrismaService, FirebaseService],
  exports: [PrescriptionService],
})
export class PrescriptionModule {}

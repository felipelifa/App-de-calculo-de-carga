import { Module } from '@nestjs/common';
import { PrController } from './pr.controller';
import { PrService } from './pr.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [PrController],
  providers: [PrService, PrismaService, FirebaseService],
  exports: [PrService],
})
export class PrModule {}

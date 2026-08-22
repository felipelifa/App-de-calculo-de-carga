import { Module } from '@nestjs/common';
import { ProController } from './pro.controller';
import { ProService } from './pro.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [ProController],
  providers: [ProService, PrismaService, FirebaseService],
  exports: [ProService],
})
export class ProModule {}

import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { FirebaseService } from '../../common/services/firebase.service';
import { PrismaService } from '../../common/services/prisma.service';

@Module({
  controllers: [AuthController],
  providers: [AuthService, FirebaseService, PrismaService],
  exports: [AuthService],
})
export class AuthModule {}

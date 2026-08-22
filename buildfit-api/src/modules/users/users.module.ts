import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService, PrismaService, FirebaseService],
  exports: [UsersService],
})
export class UsersModule {}

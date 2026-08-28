import { Global, Module } from '@nestjs/common';
import { FirebaseAuthGuard } from './guards/firebase-auth.guard';
import { ProGuard } from './guards/pro.guard';
import { FirebaseService } from './services/firebase.service';
import { PrismaService } from './services/prisma.service';

@Global()
@Module({
  providers: [PrismaService, FirebaseService, FirebaseAuthGuard, ProGuard],
  exports: [PrismaService, FirebaseService, FirebaseAuthGuard, ProGuard],
})
export class CommonModule {}

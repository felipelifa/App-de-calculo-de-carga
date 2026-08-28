import { Global, Module } from '@nestjs/common';
import { FirebaseAuthGuard } from './guards/firebase-auth.guard';
import { FirebaseService } from './services/firebase.service';
import { PrismaService } from './services/prisma.service';

@Global()
@Module({
  providers: [PrismaService, FirebaseService, FirebaseAuthGuard],
  exports: [PrismaService, FirebaseService, FirebaseAuthGuard],
})
export class CommonModule {}

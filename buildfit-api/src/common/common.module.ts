import { Global, Module } from '@nestjs/common';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { JwtAuthService } from './services/jwt.service';
import { PrismaService } from './services/prisma.service';

@Global()
@Module({
  providers: [PrismaService, JwtAuthService, JwtAuthGuard],
  exports: [PrismaService, JwtAuthService, JwtAuthGuard],
})
export class CommonModule {}

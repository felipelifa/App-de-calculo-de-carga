import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ProService } from './pro.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('pro')
@Controller('pro')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class ProController {
  constructor(private proService: ProService) {}

  @Get('status')
  @ApiOperation({ summary: 'Verificar status Pro' })
  async getStatus(@CurrentUser('uid') uid: string) {
    const user = await this.getUser(uid);
    return this.proService.getStatus(user.id);
  }

  @Post('redeem')
  @ApiOperation({ summary: 'Resgatar token Pro' })
  async redeem(
    @CurrentUser('uid') uid: string,
    @Body() body: { code: string },
  ) {
    const user = await this.getUser(uid);
    return this.proService.redeemToken(user.id, body.code);
  }

  private async getUser(uid: string) {
    const { PrismaService } = await import('../../common/services/prisma.service');
    const prisma = new PrismaService();
    await prisma.onModuleInit();
    const user = await prisma.user.findUnique({ where: { firebaseUid: uid } });
    await prisma.onModuleDestroy();
    if (!user) throw new Error('User not found');
    return user;
  }
}

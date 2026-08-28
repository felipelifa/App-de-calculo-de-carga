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
  async getStatus(@CurrentUser('id') userId: string) {
    return this.proService.getStatus(userId);
  }

  @Post('redeem')
  @ApiOperation({ summary: 'Resgatar token Pro' })
  async redeem(
    @CurrentUser('id') userId: string,
    @Body() body: { code: string },
  ) {
    return this.proService.redeemToken(userId, body.code);
  }
}

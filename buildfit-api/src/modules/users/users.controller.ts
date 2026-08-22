import { Controller, Get, Put, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('users')
@Controller('users')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Obter perfil do usuário' })
  async getProfile(@CurrentUser('uid') uid: string) {
    return this.usersService.getProfileByFirebaseUid(uid);
  }

  @Put('profile')
  @ApiOperation({ summary: 'Atualizar perfil do usuário' })
  async updateProfile(
    @CurrentUser('uid') uid: string,
    @Body() dto: UpdateProfileDto,
  ) {
    const user = await this.usersService.getProfileByFirebaseUid(uid);
    return this.usersService.updateProfile(user.id, dto);
  }
}

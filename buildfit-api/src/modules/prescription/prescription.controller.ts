import { Controller, Get, Post, Put, Delete, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PrescriptionService } from './prescription.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard';

@ApiTags('prescription')
@Controller('prescription')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class PrescriptionController {
  constructor(private prescriptionService: PrescriptionService) {}

  @Get()
  @ApiOperation({ summary: 'Obter plano de treino ativo' })
  async getActive(@CurrentUser('uid') uid: string) {
    const user = await this.getUser(uid);
    return this.prescriptionService.getActiveWorkout(user.id);
  }

  @Get('all')
  @ApiOperation({ summary: 'Listar todos os planos de treino' })
  async getAll(@CurrentUser('uid') uid: string) {
    const user = await this.getUser(uid);
    return this.prescriptionService.getAllWorkouts(user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Salvar plano de treino gerado' })
  async save(
    @CurrentUser('uid') uid: string,
    @Body() body: any,
  ) {
    const user = await this.getUser(uid);
    return this.prescriptionService.saveWorkout(user.id, body);
  }

  @Put(':id/activate')
  @ApiOperation({ summary: 'Ativar plano de treino' })
  async activate(
    @Param('id') id: string,
    @CurrentUser('uid') uid: string,
  ) {
    const user = await this.getUser(uid);
    return this.prescriptionService.activateWorkout(user.id, id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deletar plano de treino' })
  async delete(
    @Param('id') id: string,
    @CurrentUser('uid') uid: string,
  ) {
    const user = await this.getUser(uid);
    return this.prescriptionService.deleteWorkout(user.id, id);
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

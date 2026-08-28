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
  async getActive(@CurrentUser('id') userId: string) {
    return this.prescriptionService.getActiveWorkout(userId);
  }

  @Get('all')
  @ApiOperation({ summary: 'Listar todos os planos de treino' })
  async getAll(@CurrentUser('id') userId: string) {
    return this.prescriptionService.getAllWorkouts(userId);
  }

  @Post()
  @ApiOperation({ summary: 'Salvar plano de treino gerado' })
  async save(
    @CurrentUser('id') userId: string,
    @Body() body: any,
  ) {
    return this.prescriptionService.saveWorkout(userId, body);
  }

  @Put(':id/activate')
  @ApiOperation({ summary: 'Ativar plano de treino' })
  async activate(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.prescriptionService.activateWorkout(userId, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Atualizar plano de treino' })
  async update(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Body() body: any,
  ) {
    return this.prescriptionService.updateWorkout(userId, id, body);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deletar plano de treino' })
  async delete(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.prescriptionService.deleteWorkout(userId, id);
  }
}

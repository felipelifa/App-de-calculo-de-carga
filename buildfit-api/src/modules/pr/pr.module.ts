import { Module } from '@nestjs/common';
import { PrController } from './pr.controller';
import { PrService } from './pr.service';
import { CommonModule } from '../../common/common.module';

@Module({
  imports: [CommonModule],
  controllers: [PrController],
  providers: [PrService],
  exports: [PrService],
})
export class PrModule {}

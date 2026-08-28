import { Module } from '@nestjs/common';
import { ProController } from './pro.controller';
import { ProService } from './pro.service';
import { CommonModule } from '../../common/common.module';

@Module({
  imports: [CommonModule],
  controllers: [ProController],
  providers: [ProService],
  exports: [ProService],
})
export class ProModule {}

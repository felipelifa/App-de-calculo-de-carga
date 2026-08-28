import { Module } from '@nestjs/common';
import { ProgressionController } from './progression.controller';
import { ProgressionService } from './progression.service';
import { CommonModule } from '../../common/common.module';

@Module({
  imports: [CommonModule],
  controllers: [ProgressionController],
  providers: [ProgressionService],
  exports: [ProgressionService],
})
export class ProgressionModule {}

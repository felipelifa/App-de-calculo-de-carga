import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../services/prisma.service';

@Injectable()
export class ProGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Usuário não autenticado');
    }

    const dbUser = await this.prisma.user.findUnique({
      where: { firebaseUid: user.uid },
      select: { isPro: true },
    });

    if (!dbUser?.isPro) {
      throw new ForbiddenException(
        'Esta funcionalidade é exclusiva para usuários Pro. ' +
        'Adquira um token Pro ou entre em contato com o suporte.',
      );
    }

    return true;
  }
}

import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { JwtAuthService } from '../services/jwt.service';
import { PrismaService } from '../services/prisma.service';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private jwtAuth: JwtAuthService,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Token de autenticação não fornecido');
    }

    const token = authHeader.slice('Bearer '.length).trim();

    if (!token) {
      throw new UnauthorizedException('Token de autenticação não fornecido');
    }

    try {
      const decoded = this.jwtAuth.verifyToken(token);

      const dbUser = await this.prisma.user.findUnique({
        where: { id: decoded.sub },
        select: { id: true, email: true, name: true, isPro: true },
      });

      if (!dbUser) {
        throw new UnauthorizedException('Usuário não encontrado');
      }

      request.user = {
        id: dbUser.id,
        email: dbUser.email,
        name: dbUser.name,
        isPro: dbUser.isPro,
      };
      return true;
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      throw new UnauthorizedException('Token de autenticação inválido ou expirado');
    }
  }
}

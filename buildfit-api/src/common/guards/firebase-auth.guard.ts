import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { FirebaseService } from '../services/firebase.service';
import { PrismaService } from '../services/prisma.service';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(
    private firebase: FirebaseService,
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
      const decoded = await this.firebase.verifyIdToken(token);

      // All downstream user-owned queries use the database id, never the Firebase UID.
      let dbUser = await this.prisma.user.findUnique({
        where: { firebaseUid: decoded.uid },
        select: { id: true, firebaseUid: true, email: true, name: true, isPro: true },
      });

      // Client-created Firebase accounts can reach the API before /auth/register.
      if (!dbUser) {
        if (!decoded.email) {
          throw new UnauthorizedException('Usuário não possui e-mail cadastrado');
        }

        dbUser = await this.prisma.user.create({
          data: {
            firebaseUid: decoded.uid,
            email: decoded.email,
            name: decoded.name || decoded.email,
            profile: { create: {} },
          },
          select: { id: true, firebaseUid: true, email: true, name: true, isPro: true },
        });
      }

      request.user = {
        id: dbUser.id,
        uid: dbUser.firebaseUid,
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

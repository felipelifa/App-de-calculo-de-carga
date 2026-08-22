import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { FirebaseService } from '../services/firebase.service';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(private firebase: FirebaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Token de autenticação não fornecido');
    }

    const token = authHeader.split('Bearer ')[1];

    try {
      const decoded = await this.firebase.verifyIdToken(token);
      request.user = {
        uid: decoded.uid,
        email: decoded.email,
      };
      return true;
    } catch (error) {
      throw new UnauthorizedException('Token de autenticação inválido ou expirado');
    }
  }
}

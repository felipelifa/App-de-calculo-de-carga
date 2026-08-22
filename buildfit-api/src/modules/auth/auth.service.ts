import { Injectable, ConflictException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';
import { FirebaseService } from '../../common/services/firebase.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private firebase: FirebaseService,
  ) {}

  async register(dto: RegisterDto) {
    let userRecord;
    try {
      userRecord = await this.firebase.auth.createUser({
        email: dto.email,
        password: dto.password,
        displayName: dto.name,
      });
    } catch (error: any) {
      if (error.code === 'auth/email-already-exists') {
        throw new ConflictException('Este e-mail já está cadastrado');
      }
      throw error;
    }

    const user = await this.prisma.user.create({
      data: {
        firebaseUid: userRecord.uid,
        email: dto.email,
        name: dto.name,
        profile: {
          create: {},
        },
      },
      include: { profile: true },
    });

    return {
      uid: user.firebaseUid,
      email: user.email,
      name: user.name,
      isPro: user.isPro,
    };
  }

  async validateToken(idToken: string) {
    try {
      const decoded = await this.firebase.verifyIdToken(idToken);
      const user = await this.prisma.user.findUnique({
        where: { firebaseUid: decoded.uid },
        select: {
          id: true,
          firebaseUid: true,
          email: true,
          name: true,
          isPro: true,
        },
      });

      if (!user) {
        throw new UnauthorizedException('Usuário não encontrado');
      }

      return user;
    } catch (error) {
      throw new UnauthorizedException('Token inválido');
    }
  }

  async getProfile(firebaseUid: string) {
    return this.prisma.user.findUnique({
      where: { firebaseUid },
      include: {
        profile: true,
        _count: {
          select: {
            workouts: true,
            personalRecords: true,
            generatedWorkouts: true,
          },
        },
      },
    });
  }
}

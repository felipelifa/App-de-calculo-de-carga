import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getOrCreateUser(firebaseUid: string, email: string, name: string) {
    let user = await this.prisma.user.findUnique({
      where: { firebaseUid },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          firebaseUid,
          email,
          name,
          profile: { create: {} },
        },
      });
    }

    return user;
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    });

    if (!user) throw new NotFoundException('Usuário não encontrado');
    return user;
  }

  async getProfileByFirebaseUid(firebaseUid: string) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid },
      include: { profile: true },
    });

    if (!user) throw new NotFoundException('Usuário não encontrado');
    return user;
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    return this.prisma.userProfile.upsert({
      where: { userId },
      update: dto,
      create: { userId, ...dto },
    });
  }

  async updateFcmToken(firebaseUid: string, fcmToken: string) {
    return this.prisma.user.update({
      where: { firebaseUid },
      data: { fcmToken },
    });
  }

  async getProStatus(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { isPro: true },
    });
    return user?.isPro ?? false;
  }
}

import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../common/services/prisma.service';

@Injectable()
export class ProService {
  constructor(private prisma: PrismaService) {}

  async getStatus(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        isPro: true,
        proActivatedAt: true,
        proTokenUsed: true,
      },
    });
    return user;
  }

  async redeemToken(userId: string, code: string) {
    const token = await this.prisma.proToken.findUnique({
      where: { code },
    });

    if (!token) {
      throw new NotFoundException('Token inválido');
    }

    if (token.expiresAt && token.expiresAt < new Date()) {
      throw new BadRequestException('Token expirado');
    }

    if (token.maxRedemptions !== -1 && token.currentRedemptions >= token.maxRedemptions) {
      throw new BadRequestException('Token atingiu o limite de resgates');
    }

    const existingRedemption = await this.prisma.proTokenRedemption.findUnique({
      where: { tokenCode_userId: { tokenCode: code, userId } },
    });

    if (existingRedemption) {
      throw new BadRequestException('Você já resgatou este token');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (user?.isPro) {
      throw new BadRequestException('Você já é um usuário Pro');
    }

    await this.prisma.$transaction([
      this.prisma.proToken.update({
        where: { code },
        data: { currentRedemptions: { increment: 1 } },
      }),
      this.prisma.proTokenRedemption.create({
        data: { tokenCode: code, userId },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: {
          isPro: true,
          proActivatedAt: new Date(),
          proTokenUsed: code,
        },
      }),
    ]);

    return {
      success: true,
      message: 'Pro ativado com sucesso!',
    };
  }

  async getTokens() {
    return this.prisma.proToken.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        _count: { select: { redemptions: true } },
      },
    });
  }
}

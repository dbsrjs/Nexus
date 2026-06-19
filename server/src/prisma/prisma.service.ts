import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/**
 * Canonical Prisma access point for the whole app.
 *
 * Every feature module injects this service:
 *   constructor(private prisma: PrismaService) {}
 * importing from a relative path to this file, e.g.
 *   import { PrismaService } from '../prisma/prisma.service';
 */
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}

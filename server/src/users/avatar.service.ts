import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { Readable } from 'node:stream';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { StorageDriver } from '../storage/storage.driver';
import { processAvatar } from './avatar-image';
import { broadcastUserUpdated } from './user-events';
import { PublicUser, publicUserSelect } from './users.service';

/**
 * 앱이 부를 주소. **버전(키의 uuid 앞 8자)을 싣는다** — 사진을 바꾸면 주소가
 * 달라져 캐시가 저절로 갈린다. 메시지 · 이슈 · 멤버 응답이 이미 `avatarUrl` 을
 * 싣고 있어 이 값을 그 칸에 둔다 (14단계 설계 D8).
 */
export function avatarPath(userId: string, key: string): string {
  const file = key.slice(key.lastIndexOf('/') + 1);
  return `/users/${userId}/avatar?v=${file.slice(0, 8)}`;
}

/**
 * 프로필 사진. 첨부와 달리 **사용자 단위**라 `SpaceGuard` 를 지나지 않는다 —
 * 대신 열람을 `canView` 가 지킨다. 서명 URL 을 발급하지 않는 규칙(8-1)은 같다.
 */
@Injectable()
export class AvatarService {
  private readonly logger = new Logger(AvatarService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageDriver,
    private readonly realtime: RealtimeEmitter,
  ) {}

  /**
   * 본인이거나 **스페이스를 하나라도 함께 쓰면** 본다 (설계 D6).
   * 스페이스 밖 사람은 사진은커녕 그 사람이 있는지도 알 수 없어야 한다.
   */
  async canView(viewerId: string, targetId: string): Promise<boolean> {
    if (viewerId === targetId) return true;
    const shared = await this.prisma.spaceMember.findFirst({
      where: { userId: targetId, space: { members: { some: { userId: viewerId } } } },
      select: { spaceId: true },
    });
    return shared !== null;
  }

  /**
   * 올린다. 순서는 **저장소 → DB → 옛 파일 지우기**(설계 D10 · CLAUDE.md §3-3).
   * DB 가 실패하면 새 파일만 남는다(고아 — 화면에는 영향이 없다). 옛 파일
   * 지우기는 실패해도 로그만 남긴다 — 이미 새 사진이 보이고 있다.
   */
  async upload(userId: string, original: Buffer): Promise<PublicUser> {
    const image = await processAvatar(original);
    const before = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { avatarKey: true },
    });

    const key = `avatars/${userId}/${randomUUID()}.webp`;
    await this.storage.put(key, image, 'image/webp');

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarKey: key, avatarUrl: avatarPath(userId, key) },
      select: publicUserSelect,
    });

    if (before?.avatarKey) await this.deleteQuietly(before.avatarKey);
    await broadcastUserUpdated(this.prisma, this.realtime, user);
    return user;
  }

  /** 지운다. DB 를 먼저 비워 화면이 곧바로 이니셜로 돌아가게 한다. */
  async remove(userId: string): Promise<PublicUser> {
    const before = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { avatarKey: true },
    });
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarKey: null, avatarUrl: null },
      select: publicUserSelect,
    });
    if (before?.avatarKey) await this.deleteQuietly(before.avatarKey);
    await broadcastUserUpdated(this.prisma, this.realtime, user);
    return user;
  }

  /**
   * 바이트를 연다. **못 보면 · 사진이 없으면 · 없는 사람이면 전부 404** 다 —
   * 셋을 가르면 스페이스 밖에서 사람이 있는지를 캐낼 수 있다.
   */
  async open(viewerId: string, targetId: string): Promise<Readable> {
    if (!(await this.canView(viewerId, targetId))) throw this.notFound();
    const user = await this.prisma.user.findUnique({
      where: { id: targetId },
      select: { avatarKey: true },
    });
    if (!user?.avatarKey) throw this.notFound();
    return this.storage.get(user.avatarKey);
  }

  private notFound(): NotFoundException {
    return new NotFoundException('사진을 찾을 수 없습니다');
  }

  private async deleteQuietly(key: string): Promise<void> {
    try {
      await this.storage.delete(key);
    } catch (err) {
      this.logger.warn(`옛 아바타 파일을 지우지 못했습니다: ${key} — ${String(err)}`);
    }
  }
}

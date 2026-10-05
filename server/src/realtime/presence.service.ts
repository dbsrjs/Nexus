import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from './realtime-emitter';
import { Presence, SocketPresence, combinePresence } from './presence-state';

/** 마지막 소켓이 끊기고 오프라인을 알리기까지(17단계 D17). 새로고침 · 재연결에 점이 깜빡이지 않게. */
export const PRESENCE_OFFLINE_GRACE_MS = 5000;

/**
 * 프레즌스(17단계 설계 D14~D19). **소켓 연결에서 계산하고 저장하지 않는다** — 서버 메모리다.
 * DB 에 쓰면 서버가 죽을 때 모두가 「온라인」으로 굳는다. 인스턴스가 둘이 되면 Redis 로
 * 옮긴다(`redis-io.adapter` 와 같은 때 — CLAUDE.md §5 빚).
 *
 * 바뀌면 `presence:changed` 를 **그 사람의 스페이스 룸마다** 보낸다 — 함께 쓰는 스페이스 밖으로
 * 온라인 여부가 새지 않는다(D18).
 */
@Injectable()
export class PresenceService implements OnModuleDestroy {
  /** userId → (socketId → 그 소켓의 상태) */
  private readonly sockets = new Map<string, Map<string, SocketPresence>>();
  /** 마지막으로 알린 상태. 없으면 오프라인 — 같은 값을 두 번 알리지 않는다. */
  private readonly published = new Map<string, SocketPresence>();
  private readonly offlineTimers = new Map<string, NodeJS.Timeout>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeEmitter,
  ) {}

  onModuleDestroy(): void {
    for (const t of this.offlineTimers.values()) clearTimeout(t);
  }

  connected(userId: string, socketId: string): void {
    this.socketsOf(userId).set(socketId, 'online');
    this.settle(userId);
  }

  disconnected(userId: string, socketId: string): void {
    const mine = this.sockets.get(userId);
    mine?.delete(socketId);
    if (mine && mine.size > 0) {
      this.settle(userId);
      return;
    }
    this.sockets.delete(userId);
    // 그 안에 다시 붙으면 settle 이 타이머를 지우고, 바뀐 것이 없으니 알리지 않는다.
    this.clearTimer(userId);
    this.offlineTimers.set(
      userId,
      setTimeout(() => {
        this.offlineTimers.delete(userId);
        this.settle(userId);
      }, PRESENCE_OFFLINE_GRACE_MS),
    );
  }

  /** 앱이 알린 그 소켓의 상태(D16). 모르는 소켓이면 무시한다. */
  set(userId: string, socketId: string, status: SocketPresence): void {
    const mine = this.sockets.get(userId);
    if (!mine?.has(socketId)) return;
    mine.set(socketId, status);
    this.settle(userId);
  }

  /** 지금 상태. 오프라인 유예 중이면 아직 마지막으로 알린 값이다. */
  statusOf(userId: string): Presence {
    return this.published.get(userId) ?? 'offline';
  }

  /** `GET .../presence` — 주어진 사람 중 오프라인이 아닌 사람만(D19). */
  snapshot(userIds: string[]): Record<string, SocketPresence> {
    const out: Record<string, SocketPresence> = {};
    for (const id of userIds) {
      const s = this.published.get(id);
      if (s) out[id] = s;
    }
    return out;
  }

  private socketsOf(userId: string): Map<string, SocketPresence> {
    this.clearTimer(userId);
    let mine = this.sockets.get(userId);
    if (!mine) {
      mine = new Map();
      this.sockets.set(userId, mine);
    }
    return mine;
  }

  private clearTimer(userId: string): void {
    const t = this.offlineTimers.get(userId);
    if (t) {
      clearTimeout(t);
      this.offlineTimers.delete(userId);
    }
  }

  /** 지금 상태를 계산해 알린 값과 다르면 알린다. 유예 중에는 알리지 않는다. */
  private settle(userId: string): void {
    if (this.offlineTimers.has(userId)) return;
    const next = combinePresence(this.sockets.get(userId)?.values() ?? []);
    const prev = this.statusOf(userId);
    if (next === prev) return;
    if (next === 'offline') this.published.delete(userId);
    else this.published.set(userId, next);
    void this.broadcast(userId, next);
  }

  private async broadcast(userId: string, status: Presence): Promise<void> {
    try {
      const spaces = await this.prisma.spaceMember.findMany({
        where: { userId },
        select: { spaceId: true },
      });
      for (const { spaceId } of spaces) {
        this.realtime.toSpace(spaceId, 'presence:changed', { userId, status });
      }
    } catch {
      // 알리지 못해도 상태는 맞다 — 앱이 재연결 · 스페이스 진입 때 처음 값을 다시 받는다(D19).
    }
  }
}

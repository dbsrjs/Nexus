import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { ChannelKind, SpaceMember } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ChannelsService } from '../channels/channels.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';
import { LiveKitClient } from './livekit.client';
import { resolveVoiceConfig } from './voice.config';
import {
  activeIdentities,
  canPublishNow,
  parseVoiceRoomName,
  sameIds,
  voiceRoomName,
} from './voice-room';

/** 웹훅이 빠져도 상태가 이 간격 안에 맞춰진다. LiveKit 은 웹훅 전달을 보장하지 않는다. */
export const VOICE_RESYNC_MS = 30_000;

const CHANNEL_ROOM_PREFIX = 'channel:';

/** 한 음성 채널의 지금 상태. */
interface VoiceRoomState {
  spaceId: string;
  userIds: string[];
}

/**
 * 음성 채널(20단계 설계). **판정은 Nexus 가 하고 미디어는 LiveKit 이 나른다** — 디스코드가 메인
 * 게이트웨이에서 음성 서버 주소와 토큰을 주는 것과 같은 모양이다.
 *
 * - 들어가기: 볼 수 있으면 토큰을 준다(`ChannelsService` 한 곳의 판정). 말하기 · 화면 공유는 보내기 권한
 * - 통화 중인 사람: **서버 메모리**다(프레즌스와 같은 판단 — 17-2). 원본은 LiveKit 의 참가자 목록이고
 *   웹훅은 「다시 물어보라」는 신호로만 쓴다 — 순서 · 누락에 흔들리지 않는다
 * - 끊기: 토큰은 들어갈 때 한 번만 검사된다. 볼 수 없게 되면(`evict`) 서버가 직접 내보낸다
 */
@Injectable()
export class VoiceService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(VoiceService.name);
  private readonly client: LiveKitClient | null;
  /** channelId → 상태. 아무도 없으면 지운다. */
  private readonly rooms = new Map<string, VoiceRoomState>();
  /** 같은 룸의 갱신을 한 줄로 세운다 — 웹훅 둘이 겹쳐 옛 목록이 나중에 착지하지 않게. */
  private readonly queues = new Map<string, Promise<void>>();
  private timer: NodeJS.Timeout | null = null;
  /** LiveKit 에 닿지 않는 동안 — 30초마다 같은 경고를 쌓지 않고 바뀔 때만 남긴다. */
  private unreachable = false;

  constructor(
    config: ConfigService,
    jwt: JwtService,
    private readonly prisma: PrismaService,
    private readonly channels: ChannelsService,
    private readonly realtime: RealtimeEmitter,
  ) {
    // 설정 해석은 부팅 때 한 번. 반쯤 채운 값이면 여기서 부팅이 멈춘다.
    const resolved = resolveVoiceConfig(config);
    this.client = resolved ? new LiveKitClient(resolved, jwt) : null;
  }

  get enabled(): boolean {
    return this.client !== null;
  }

  onModuleInit(): void {
    if (!this.client) {
      this.logger.log('LIVEKIT_* 가 비어 있습니다 — 통화가 꺼진 채로 뜹니다');
      return;
    }
    this.realtime.onEvict((userId, rooms) => this.onEvicted(userId, rooms));
    // 서버가 재시작되면 메모리가 비어 있다 — 이미 통화 중인 사람을 다시 센다.
    void this.resync();
    this.timer = setInterval(() => void this.resync(), VOICE_RESYNC_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  // ──────────────────────────────────────────────
  // REST
  // ──────────────────────────────────────────────

  /**
   * 들어갈 토큰. 볼 수 없는 채널은 404(존재를 흘리지 않는다), 음성 채널이 아니면 400.
   * 보낼 수 없는 사람(읽기 전용)은 듣기만 하는 토큰을 받는다.
   */
  async issueToken(member: SpaceMember, channelId: string) {
    // 볼 수 있는지가 먼저다 — 통화가 꺼진 서버에서도 남의 채널에는 503 이 아니라 404 를 준다.
    const channel = await this.channels.assertCanView(channelId, member);
    const client = this.requireClient();
    if (channel.kind !== ChannelKind.voice) {
      throw new BadRequestException('음성 채널이 아닙니다');
    }
    const [canSpeak, user] = await Promise.all([
      this.channels.canSend(channelId, member),
      this.prisma.user.findUnique({
        where: { id: member.userId },
        select: { name: true },
      }),
    ]);
    if (!user) throw new NotFoundException('사용자를 찾을 수 없습니다');

    const room = voiceRoomName(member.spaceId, channelId);
    const token = await client.joinToken({
      room,
      identity: member.userId,
      name: user.name,
      canPublish: canSpeak,
    });
    return { url: client.url, token, canSpeak };
  }

  /**
   * 지금 통화 중인 사람 — **내가 볼 수 있는 채널만**. 앱이 처음 켜졌을 때의 값이다.
   * 이후는 `voice:state` 이벤트가 채널 룸으로 온다.
   */
  async snapshot(member: SpaceMember): Promise<Record<string, string[]>> {
    const out: Record<string, string[]> = {};
    if (!this.client) return out;
    const viewable = new Set(await this.channels.viewableChannelIds(member));
    for (const [channelId, state] of this.rooms) {
      if (state.spaceId === member.spaceId && viewable.has(channelId)) {
        out[channelId] = state.userIds;
      }
    }
    return out;
  }

  /** 웹훅 — 서명이 맞으면 그 룸을 다시 묻는다. 서명이 틀리면 false(401). */
  async handleWebhook(
    raw: Buffer | undefined,
    auth: string | undefined,
  ): Promise<boolean> {
    const client = this.client;
    if (!client) throw new NotFoundException();
    if (!raw || !(await client.verifyWebhook(raw, auth))) return false;

    let event: { event?: string; room?: { name?: string } };
    try {
      event = JSON.parse(raw.toString('utf8'));
    } catch {
      return true; // 서명은 맞는데 읽을 수 없다 — 재시도해도 같다. 받은 것으로 친다.
    }
    const name = event.room?.name;
    if (parseVoiceRoomName(name)) await this.refresh(name!);
    return true;
  }

  /** 채널 권한이 바뀌었을 때(권한 설정) — 그 채널에 있는 사람을 다시 판정한다. */
  async reconcileChannel(spaceId: string, channelId: string): Promise<void> {
    if (!this.client || !this.rooms.has(channelId)) return;
    await this.refresh(voiceRoomName(spaceId, channelId));
  }

  // ──────────────────────────────────────────────
  // 상태 맞추기
  // ──────────────────────────────────────────────

  /** LiveKit 의 룸 전부를 다시 묻는다. 없어진 룸은 비운다. */
  async resync(): Promise<void> {
    const client = this.client;
    if (!client) return;
    let names: string[];
    try {
      names = (await client.listRooms()).filter((n) => parseVoiceRoomName(n));
    } catch (err) {
      // 개발 PC 는 .env 에 개발값이 들어 있어도 LiveKit 을 안 띄운 날이 많다(통화를 만지는 날만 켠다).
      if (!this.unreachable) {
        this.logger.warn(
          `LiveKit 룸 목록을 받지 못했습니다 — 닿을 때까지 다시 알리지 않습니다: ${(err as Error).message}`,
        );
      }
      this.unreachable = true;
      return;
    }
    if (this.unreachable) this.logger.log('LiveKit 에 다시 닿았습니다');
    this.unreachable = false;
    const live = new Set(names.map((n) => parseVoiceRoomName(n)!.channelId));
    for (const [channelId, state] of [...this.rooms]) {
      if (!live.has(channelId)) this.apply(channelId, state.spaceId, []);
    }
    await Promise.all(names.map((n) => this.refresh(n)));
  }

  /** 룸 하나를 다시 묻는다. 같은 룸은 한 줄로 선다. */
  private refresh(roomName: string): Promise<void> {
    const prev = this.queues.get(roomName) ?? Promise.resolve();
    const next = prev
      .then(() => this.refreshNow(roomName))
      .catch((err: Error) =>
        this.logger.warn(`통화 상태를 맞추지 못했습니다(${roomName}): ${err.message}`),
      );
    this.queues.set(roomName, next);
    void next.finally(() => {
      if (this.queues.get(roomName) === next) this.queues.delete(roomName);
    });
    return next;
  }

  /**
   * 참가자를 다시 판정하고 상태를 알린다(20단계 설계 V6 · V7).
   *
   * - 그 채널이 이 스페이스의 음성 채널이 아니면 룸을 무시한다 — 이름을 지어낸 룸은 없다
   * - **볼 수 없는 사람은 내보낸다**, 말하기 권한이 바뀐 사람은 고친다
   */
  private async refreshNow(roomName: string): Promise<void> {
    const client = this.client!;
    const parsed = parseVoiceRoomName(roomName);
    if (!parsed) return;
    const { spaceId, channelId } = parsed;

    const channel = await this.prisma.channel.findFirst({
      where: { id: channelId, spaceId, kind: ChannelKind.voice },
      select: { id: true },
    });
    if (!channel) {
      if (this.rooms.has(channelId)) this.apply(channelId, spaceId, []);
      return;
    }

    const participants = await client.listParticipants(roomName);
    const ids = activeIdentities(participants);
    const members = await this.prisma.spaceMember.findMany({
      where: { spaceId, userId: { in: ids } },
    });
    const memberOf = new Map(members.map((m) => [m.userId, m]));

    const stays: string[] = [];
    for (const userId of ids) {
      const member = memberOf.get(userId);
      const view = member ? await this.channels.canView(channelId, member) : false;
      if (!view) {
        await client.removeParticipant(roomName, userId);
        continue;
      }
      stays.push(userId);
      const speak = await this.channels.canSend(channelId, member!);
      const p = participants.find((x) => x.identity === userId);
      if (p && canPublishNow(p) !== speak) {
        await client.setCanPublish(roomName, userId, speak);
      }
    }
    this.apply(channelId, spaceId, stays);
  }

  /** 바뀌었으면 그 채널 룸에 알린다. 채널 룸에는 볼 수 있는 사람만 있다(4단계). */
  private apply(channelId: string, spaceId: string, userIds: string[]): void {
    const before = this.rooms.get(channelId)?.userIds ?? [];
    if (userIds.length === 0) this.rooms.delete(channelId);
    else this.rooms.set(channelId, { spaceId, userIds });
    if (sameIds(before, userIds)) return;
    this.realtime.toChannel(channelId, 'voice:state', { spaceId, channelId, userIds });
  }

  /**
   * 볼 수 없게 된 채널이 음성 채널이면 다시 판정한다 — 판정이 내보낸다. **우리가 아는 통화가
   * 없어도 묻는다**: 웹훅은 전달이 보장되지 않고, 붙는 중(JOINING)이던 사람은 아직 세지 않았다.
   * 그 틈에 남은 참가자는 다음 맞추기(30초)까지 듣게 된다 — 실제로 검증에서 드러났다.
   */
  private onEvicted(_userId: string, rooms: string[]): void {
    const ids = rooms
      .filter((n) => n.startsWith(CHANNEL_ROOM_PREFIX))
      .map((n) => n.slice(CHANNEL_ROOM_PREFIX.length));
    if (ids.length === 0) return;
    void this.prisma.channel
      .findMany({
        where: { id: { in: ids }, kind: ChannelKind.voice },
        select: { id: true, spaceId: true },
      })
      .then((voice) =>
        Promise.all(voice.map((c) => this.refresh(voiceRoomName(c.spaceId, c.id)))),
      )
      .catch((err: Error) =>
        this.logger.warn(`내보낸 사람의 통화를 확인하지 못했습니다: ${err.message}`),
      );
  }

  private requireClient(): LiveKitClient {
    if (!this.client) {
      throw new ServiceUnavailableException('이 서버에는 통화가 설정되지 않았습니다');
    }
    return this.client;
  }
}

import {
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { SpaceMember } from '@prisma/client';
import type { Request } from 'express';
import { Public } from '../common/decorators/public.decorator';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { CurrentSpaceMember } from '../spaces/decorators/current-space-member.decorator';
import { VoiceService } from './voice.service';

/** rawBody 는 `NestFactory.create(..., { rawBody: true })` 와 main.ts 의 웹훅 파서가 채워 준다. */
type RawBodyRequest = Request & { rawBody?: Buffer };

/**
 * 음성 채널(20단계 설계 V5). 미디어는 여기를 지나지 않는다 — 앱은 받은 토큰으로 LiveKit 에 직접 붙는다.
 */
@Controller()
export class VoiceController {
  constructor(private readonly voice: VoiceService) {}

  /**
   * 이 서버에서 통화를 쓸 수 있는가. 꺼져 있으면 앱이 음성 채널 만들기 · 들어가기를 보이지 않는다 —
   * 눌러 봐야 실패할 버튼은 만들지 않는다(CLAUDE.md §3-7).
   */
  @Get('voice')
  status() {
    return { enabled: this.voice.enabled };
  }

  /** 들어갈 토큰. **읽기 라우트처럼 `@MinRole` 을 걸지 않는다** — 판정은 채널 가시성이다. */
  @Post('spaces/:spaceId/channels/:channelId/voice/token')
  @UseGuards(SpaceGuard)
  @HttpCode(HttpStatus.OK)
  token(
    @Param('channelId', new ParseUUIDPipe()) channelId: string,
    @CurrentSpaceMember() member: SpaceMember,
  ) {
    return this.voice.issueToken(member, channelId);
  }

  /** 지금 통화 중인 사람 — 볼 수 있는 음성 채널만. `{ channels: { [channelId]: userId[] } }` */
  @Get('spaces/:spaceId/voice')
  @UseGuards(SpaceGuard)
  async snapshot(@CurrentSpaceMember() member: SpaceMember) {
    return { channels: await this.voice.snapshot(member) };
  }

  /**
   * LiveKit 웹훅. **`@Public()` 이지만 서명이 곧 인증이다**(CLAUDE.md §3-14) — LiveKit 이 API
   * 시크릿으로 서명한 JWT 에 원문 바이트의 해시가 실려 온다. 통화가 꺼져 있으면 404.
   */
  @Public()
  @Post('voice/webhook')
  @HttpCode(HttpStatus.OK)
  async webhook(
    @Headers('authorization') auth: string | undefined,
    @Req() req: RawBodyRequest,
  ) {
    if (!(await this.voice.handleWebhook(req.rawBody, auth))) {
      throw new UnauthorizedException('서명이 올바르지 않습니다');
    }
    return { ok: true };
  }
}

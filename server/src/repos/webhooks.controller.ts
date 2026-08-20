import {
  Body,
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UnauthorizedException,
} from '@nestjs/common';
import { RepoProvider } from '@prisma/client';
import type { Request } from 'express';
import { Public } from '../common/decorators/public.decorator';
import { ReposService } from './repos.service';
import { WebhooksService } from './webhooks.service';
import { verifySignature } from './webhook-signature';

/** rawBody 는 `NestFactory.create(..., { rawBody: true })` 가 채워 준다. */
type RawBodyRequest = Request & { rawBody?: Buffer };

/**
 * provider 웹훅 수신 (docs/백엔드-설계.md §7.2).
 *
 * **`@Public()` 이지만 아무나 부를 수 있는 것은 아니다.** 부르는 쪽이
 * GitHub 이라 JWT 를 요구할 수 없어, 저장소마다 다른 시크릿으로 만든
 * HMAC 서명이 곧 인증이다.
 */
@Controller('webhooks')
export class WebhooksController {
  constructor(
    private readonly repos: ReposService,
    private readonly webhooks: WebhooksService,
  ) {}

  @Public()
  @Post(':provider/:repoId')
  @HttpCode(HttpStatus.OK)
  async receive(
    @Param('provider') provider: string,
    @Param('repoId', new ParseUUIDPipe()) repoId: string,
    @Headers('x-hub-signature-256') signature: string | undefined,
    @Headers('x-github-event') event: string | undefined,
    @Headers('x-github-delivery') deliveryId: string | undefined,
    @Req() req: RawBodyRequest,
    @Body() payload: unknown,
  ) {
    if (!isProvider(provider)) {
      throw new NotFoundException('알 수 없는 provider 입니다');
    }

    const repo = await this.repos.findForWebhook(repoId, provider);
    // 저장소를 못 찾은 것과 서명이 틀린 것을 같은 코드로 뭉개지 않는다 —
    // 웹훅을 붙이는 사람이 무엇이 틀렸는지 알아야 한다.
    if (!repo || !repo.webhookSecret) {
      throw new NotFoundException('저장소를 찾을 수 없습니다');
    }

    // **원문 바이트로 검증한다.** 파싱된 객체를 다시 직렬화하면 키 순서와
    // 공백이 달라져 멀쩡한 요청이 위조로 판정된다.
    const raw = req.rawBody;
    if (!raw || !verifySignature(raw, signature, repo.webhookSecret)) {
      throw new UnauthorizedException('서명이 올바르지 않습니다');
    }

    const result = await this.webhooks.handle(
      repo,
      event ?? '',
      deliveryId ?? null,
      payload,
    );

    // **언제나 200 이다.** 우리가 안 쓰는 이벤트에 실패를 돌려주면 GitHub 이
    // 재시도하고 저장소 설정 화면이 빨갛게 된다.
    return { ok: true, ...result };
  }
}

function isProvider(value: string): value is RepoProvider {
  return value === RepoProvider.github || value === RepoProvider.gitlab;
}

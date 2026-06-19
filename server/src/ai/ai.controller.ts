import { Controller, HttpException, HttpStatus, Post } from '@nestjs/common';

/**
 * AI 코드 분석 스텁 (design doc §1 / §8 — 코드 외부유출 정책 확정 전까지 보류).
 *
 * 실제 분석 파이프라인(GitLab 코드 + 로그 → RAG → LLM)은 Phase 2에서 구현한다.
 * 현재는 항상 501 Not Implemented 를 반환한다.
 */
@Controller('ai')
export class AiController {
  /** POST /api/ai/analyze — 501 Not Implemented (준비 중 스텁). */
  @Post('analyze')
  analyze(): never {
    throw new HttpException(
      'AI 코드 분석 기능은 준비 중입니다.',
      HttpStatus.NOT_IMPLEMENTED,
    );
  }
}

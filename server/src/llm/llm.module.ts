import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LLM_PROVIDER, LlmProvider } from './llm.provider';
import { resolveLlm } from './llm.config';
import { FakeLlmProvider } from './fake-llm.provider';
import { GeminiLlmProvider } from './gemini-llm.provider';
import { LocalLlmProvider } from './local-llm.provider';

/**
 * 설정을 보고 provider 를 하나 고른다.
 *
 * **`@Global` 이 아니다.** 임베딩은 인덱싱과 AI 둘이 쓰지만 LLM 은 AI 만
 * 쓴다. 전역이면 아무 데서나 부를 수 있게 되어 `ai_runs` 기록을 우회하는
 * 경로가 생긴다 (설계 §1).
 *
 * **`null` 을 제공하는 것이 정상 경로다.** 설정이 없으면 서버는 그대로 뜨고
 * AI 만 멈춘다.
 */
@Module({
  providers: [
    {
      provide: LLM_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService): LlmProvider | null => {
        const logger = new Logger('LlmModule');
        const resolved = resolveLlm(config);

        if (!resolved) {
          logger.warn(
            'LLM_PROVIDER 가 설정되지 않아 AI 가 꺼져 있습니다. ' +
              '서버의 다른 기능은 그대로 동작합니다.',
          );
          return null;
        }

        logger.log(`LLM provider: ${resolved.provider} (${resolved.model})`);
        if (resolved.provider === 'fake') return new FakeLlmProvider();
        if (resolved.provider === 'local') return new LocalLlmProvider(resolved);
        return new GeminiLlmProvider(resolved);
      },
    },
  ],
  exports: [LLM_PROVIDER],
})
export class LlmModule {}

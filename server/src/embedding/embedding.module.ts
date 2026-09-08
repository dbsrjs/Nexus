import { Global, Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EMBEDDING_PROVIDER, EmbeddingProvider } from './embedding.provider';
import { resolveEmbedding } from './embedding.config';
import { FakeEmbeddingProvider } from './fake-embedding.provider';

/**
 * 설정을 보고 provider 를 하나 고른다.
 *
 * **`@Global` 인 이유**는 13단계 AI 가 질문을 임베딩할 때 같은 것을 쓰기
 * 때문이다. 저장소 모듈 밑에 두면 AI 가 저장소에 의존하게 된다.
 *
 * **`null` 을 제공하는 것이 정상 경로다.** 설정이 없으면 서버는 그대로 뜨고
 * 인덱싱만 멈춘다 — 대화 · 이슈 · 첨부는 전부 돈다.
 */
@Global()
@Module({
  providers: [
    {
      provide: EMBEDDING_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService): EmbeddingProvider | null => {
        const logger = new Logger('EmbeddingModule');
        const resolved = resolveEmbedding(config);

        if (!resolved) {
          logger.warn(
            'EMBEDDING_PROVIDER 가 설정되지 않아 인덱싱이 꺼져 있습니다. ' +
              '서버의 다른 기능은 그대로 동작합니다.',
          );
          return null;
        }

        logger.log(`임베딩 provider: ${resolved.provider} (${resolved.model})`);
        if (resolved.provider === 'fake') return new FakeEmbeddingProvider();

        // gemini · local 은 Task 10 에서 붙인다. 그때까지는 미설정과 같게 둔다.
        logger.warn(`${resolved.provider} 어댑터가 아직 없습니다.`);
        return null;
      },
    },
  ],
  exports: [EMBEDDING_PROVIDER],
})
export class EmbeddingModule {}

import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

/**
 * ESLint 9 flat config.
 *
 * 규칙을 많이 켜지 않는다. 이 저장소는 사람이 읽는 주석과 설명이 많은 편이라,
 * 스타일 규칙을 촘촘히 걸면 유지 비용만 늘고 잡는 버그는 없다.
 * **타입 오류는 tsc 가, 서식은 prettier 가 잡는다.** ESLint 는 그 둘이 못 잡는
 * 것(미사용 변수 · 잘못된 await 등)만 본다.
 */
export default tseslint.config(
  {
    // 미이관 모듈이 있던 시절의 목록(permissions · notifications · issues · ai …)을 2026-10-06 에 비웠다 —
    // 다시 쓴 모듈이 그 뒤로도 남아 **린트를 한 번도 받지 않았다.** tsconfig 의 exclude 와 같은 것만 둔다.
    ignores: [
      'dist/**',
      'node_modules/**',
      'coverage/**',
      'src/realtime/redis-io.adapter.ts',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  prettier,
  {
    languageOptions: {
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module',
      },
    },
    rules: {
      // NestJS 는 데코레이터로 배선하므로 인터페이스 구현체에 빈 메서드가 흔하다.
      '@typescript-eslint/no-empty-function': 'off',
      // 의도적으로 버리는 인자는 _ 접두사로 표시한다.
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      // any 는 경고까지만. Prisma 의 Unsupported 타입 등에서 불가피한 곳이 있다.
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
);

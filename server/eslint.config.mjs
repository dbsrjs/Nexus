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
    // 미이관 모듈은 컴파일되지 않는다. tsconfig.build.json 의 exclude 와 같은 목록.
    ignores: [
      'dist/**',
      'node_modules/**',
      'coverage/**',
      'src/permissions/**',
      'src/notifications/**',
      'src/files/**',
      'src/issues/**',
      'src/gitlab/**',
      'src/ai/**',
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

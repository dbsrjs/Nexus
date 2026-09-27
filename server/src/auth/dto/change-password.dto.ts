import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

/** POST /api/auth/password. 새 비밀번호 규칙은 가입(`SignupDto`)과 같다 — 규칙이 두 벌이면 어긋난다. */
export class ChangePasswordDto {
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  currentPassword!: string;

  @IsString()
  @MinLength(10, { message: '비밀번호는 10자 이상이어야 합니다' })
  @MaxLength(128)
  newPassword!: string;

  /** signup.dto.ts 의 client 와 같은 의미. 웹이면 새 리프레시 토큰을 쿠키로 준다. */
  @IsOptional()
  @IsIn(['web', 'native'])
  client?: 'web' | 'native';
}

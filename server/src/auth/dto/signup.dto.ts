import { IsEmail, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SignupDto {
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다' })
  email!: string;

  @IsString()
  @MinLength(10, { message: '비밀번호는 10자 이상이어야 합니다' })
  @MaxLength(128)
  password!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(50)
  name!: string;

  /**
   * 'web' 이면 리프레시 토큰을 HttpOnly 쿠키로만 내려보낸다 (XSS 노출 축소).
   * 네이티브는 보안 저장소를 쓰므로 응답 바디로 받는다 (docs/백엔드-설계.md §6).
   */
  @IsOptional()
  @IsIn(['web', 'native'])
  client?: 'web' | 'native';
}

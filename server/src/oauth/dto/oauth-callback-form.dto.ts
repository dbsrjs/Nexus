import { IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * 확인 화면의 폼(`application/x-www-form-urlencoded`). 둘 다 비어 올 수 있다 —
 * 판정은 `completeGithub()` 가 하고, 빠진 값은 실패 화면이 된다(400 JSON 이 아니라).
 */
export class OauthCallbackFormDto {
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  code?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2048)
  state?: string;
}

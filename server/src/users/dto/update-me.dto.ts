import { UserStatus } from '@prisma/client';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

const STATUSES: UserStatus[] = ['online', 'away', 'offline'];

/**
 * **`avatarUrl` 을 받지 않는다**(14단계 설계 D9). 예전에는 임의 URL 을 받았는데,
 * 그 주소를 앱이 부르게 되면 추적 픽셀이 된다. 사진은 `PUT /api/me/avatar` 로
 * 올리고 주소는 서버가 만든다. 보내면 전역 파이프가 400 으로 거부한다.
 */
export class UpdateMeDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(50)
  name?: string;

  @IsOptional()
  @IsIn(STATUSES)
  globalStatus?: UserStatus;
}

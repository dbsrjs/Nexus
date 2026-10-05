import { IsBoolean, IsOptional } from 'class-validator';

/**
 * PATCH /api/me/notification-settings(18단계 설계 N10) — **부분 갱신**이다. 스위치 하나를
 * 누를 때 나머지를 몰라도 된다. 모르는 필드는 전역 파이프가 400 으로 거부한다.
 */
export class UpdateNotificationSettingsDto {
  @IsOptional()
  @IsBoolean()
  mentions?: boolean;

  @IsOptional()
  @IsBoolean()
  broadcast?: boolean;

  @IsOptional()
  @IsBoolean()
  dms?: boolean;

  @IsOptional()
  @IsBoolean()
  replies?: boolean;
}

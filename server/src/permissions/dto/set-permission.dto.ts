import { IsBoolean } from 'class-validator';

/** 한 역할의 채널 권한 — 둘 다 준다. 기본값으로 돌리려면 DELETE 를 쓴다(행을 지운다). */
export class SetPermissionDto {
  @IsBoolean()
  canView!: boolean;

  @IsBoolean()
  canSend!: boolean;
}

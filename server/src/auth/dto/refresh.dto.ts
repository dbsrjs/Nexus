import { IsIn, IsOptional, IsString } from 'class-validator';

export class RefreshDto {
  /**
   * 네이티브 클라이언트가 보낸다. 웹은 HttpOnly 쿠키로 자동 전송되므로 비워 둔다.
   * 둘 다 없으면 401.
   */
  @IsOptional()
  @IsString()
  refreshToken?: string;

  @IsOptional()
  @IsIn(['web', 'native'])
  client?: 'web' | 'native';
}

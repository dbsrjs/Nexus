import { IsInt, IsOptional, IsPositive, IsUUID } from 'class-validator';

/**
 * 자동 등록. **숫자 id 하나만 받는다.**
 *
 * 경로(`소유자/이름`)를 클라이언트가 보내게 하면 남의 저장소 이름으로 행을
 * 만들 수 있고, `permissions.admin` 도 확인할 수 없다. 서버가 그 id 로
 * GitHub 에 물어 이름 · 기본 브랜치 · 권한을 받아 온다.
 */
export class ConnectRepoDto {
  /** GitHub 의 저장소 숫자 id. 이름이 바뀌어도 변하지 않는다. */
  @IsInt()
  @IsPositive()
  githubRepoId!: number;

  /** 비우면 이벤트를 적재만 하고 채널에는 올리지 않는다(10-1 과 같다). */
  @IsOptional()
  @IsUUID()
  linkedChannelId?: string;
}

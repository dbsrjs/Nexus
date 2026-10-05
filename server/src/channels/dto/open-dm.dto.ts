import { IsUUID } from 'class-validator';

/** POST /api/spaces/:spaceId/dms — 그 사람과의 DM 을 연다(17단계 D3). */
export class OpenDmDto {
  @IsUUID()
  userId!: string;
}

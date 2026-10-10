import {
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class CreateChannelDto {
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  name!: string;

  /** URL·멘션에 쓰이는 식별자. 비우면 name 에서 만든다. 스페이스 안에서 유일하다. */
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, {
    message: 'key 는 소문자·숫자·하이픈만 쓸 수 있습니다',
  })
  key?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  topic?: string;

  @IsOptional()
  @IsUUID()
  categoryId?: string;

  /**
   * `text`(기본) · `voice`(20단계). DM 은 이 경로로 만들지 않는다 — `POST .../dms` 가 만든다.
   * 만든 뒤에는 바꾸지 않는다 — 글 채널의 메시지가 음성 채널에 남으면 보일 곳이 없다.
   */
  @IsOptional()
  @IsIn(['text', 'voice'])
  kind?: 'text' | 'voice';

  /** true 면 채널 멤버만 볼 수 있다. */
  @IsOptional()
  @IsBoolean()
  isPrivate?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  position?: number;
}

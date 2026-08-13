import { IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class CreateSpaceDto {
  @IsString()
  @MinLength(1)
  @MaxLength(60)
  name!: string;

  /**
   * URL 에 노출되는 식별자. 소문자·숫자·하이픈만 허용한다.
   * 비우면 name 에서 만들어 낸다.
   */
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(40)
  @Matches(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, {
    message: 'slug 는 소문자·숫자·하이픈만 쓸 수 있습니다',
  })
  slug?: string;
}

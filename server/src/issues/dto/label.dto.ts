import { ArrayMaxSize, IsArray, IsString, Matches, MaxLength, MinLength, IsUUID } from 'class-validator';

/** `#RRGGBB`. 이름은 스페이스 안에서 유일하다(스키마 UNIQUE). */
export class CreateIssueLabelDto {
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  name!: string;

  @IsString()
  @Matches(/^#[0-9a-fA-F]{6}$/, {
    message: '색은 #RRGGBB 형식이어야 합니다',
  })
  color!: string;
}

/**
 * 이슈에 붙은 라벨을 **통째로 교체**한다. 추가·제거를 따로 두지 않는 이유는
 * 멱등하기 때문이다 — 같은 요청을 다시 보내도 결과가 같고, 화면이 "지금 선택된
 * 것"을 그대로 보내면 되어 클라이언트가 차집합을 계산할 일이 없다.
 */
export class SetIssueLabelsDto {
  @IsArray()
  @ArrayMaxSize(20)
  @IsUUID(undefined, { each: true })
  labelIds!: string[];
}

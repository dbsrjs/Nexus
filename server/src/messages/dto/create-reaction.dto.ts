import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class CreateReactionDto {
  /**
   * 이모지 한 글자(결합 문자 포함).
   *
   * 길이로만 막는 이유: 유니코드 이모지 판정을 서버가 정확히 하려면 표를
   * 들고 있어야 하고, 표는 유니코드 개정마다 낡는다. 임의의 긴 문자열을
   * 거르는 것이 목적이므로 **공백 금지 + 짧은 길이**면 충분하다.
   * 결합 이모지(예: 👩‍💻, 🇰🇷)는 코드 유닛이 여러 개라 넉넉히 잡는다.
   */
  @IsString()
  @MinLength(1)
  @MaxLength(16)
  @Matches(/^\S+$/u, { message: '이모지에 공백을 넣을 수 없습니다' })
  emoji!: string;
}

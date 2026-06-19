import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class UpdateMessageDto {
  @IsString()
  @IsNotEmpty({ message: '메시지 본문은 비어 있을 수 없습니다.' })
  @MaxLength(10000)
  body!: string;
}

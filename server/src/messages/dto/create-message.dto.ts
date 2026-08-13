import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateMessageDto {
  @IsString()
  @IsNotEmpty({ message: '메시지 본문은 비어 있을 수 없습니다' })
  @MaxLength(10000)
  body!: string;

  // NOTE: 스레드 답글(parentId)은 스레드 기능과 함께 뒤 단계에서 추가한다.
  // 스키마에는 이미 Message.parentId 가 있다.
}

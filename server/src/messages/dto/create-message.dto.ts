import { IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateMessageDto {
  @IsString()
  @IsNotEmpty({ message: '메시지 본문은 비어 있을 수 없습니다' })
  @MaxLength(10000)
  body!: string;

  /**
   * 스레드 답글이면 부모 메시지 id.
   *
   * 답글의 답글은 받지 않는다(서비스에서 400). 스레드를 한 겹으로 두면 목록이
   * 언제나 `parent_id IS NULL` 한 줄로 갈리고, 화면도 채널 · 스레드 둘로 끝난다.
   */
  @IsOptional()
  @IsUUID()
  parentId?: string;

  /**
   * 답장(인용)이 가리키는 메시지 id.
   *
   * `parentId` 와 함께 쓸 수 있다 — 스레드 안에서 특정 답글을 가리키는 경우다.
   * 둘은 다른 축이라 서로를 막지 않는다.
   */
  @IsOptional()
  @IsUUID()
  quotedMessageId?: string;
}

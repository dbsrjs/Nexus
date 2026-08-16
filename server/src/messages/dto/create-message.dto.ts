import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { MAX_ATTACHMENTS_PER_MESSAGE } from '../../attachments/attachments.service';

export class CreateMessageDto {
  /**
   * 첨부만 보내는 경우가 있어 **본문이 없어도 된다**. 다만 본문도 첨부도 없으면
   * 아무것도 아닌 메시지라 서비스가 400 으로 막는다 — 그 검사는 두 값을 함께
   * 봐야 해서 DTO 에 담기지 않는다.
   */
  @IsOptional()
  @IsString()
  @MaxLength(10000)
  body?: string;

  /**
   * 먼저 올려 둔 첨부의 id. 전송과 **같은 트랜잭션**에서 연결된다.
   *
   * 파일을 메시지와 함께 올리지 않는 이유: 고른 즉시 올려 두어야 전송이 빠르고,
   * 큰 파일이 올라가는 동안에도 본문을 계속 쓸 수 있다.
   */
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(MAX_ATTACHMENTS_PER_MESSAGE)
  @IsUUID('4', { each: true })
  attachmentIds?: string[];

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

import { IsOptional, IsString, IsUUID } from 'class-validator';

/**
 * Multipart form fields that accompany a file upload to a channel.
 * The binary part itself is handled by FileInterceptor; these are the
 * extra text fields in the same multipart body.
 */
export class UploadFileDto {
  /** Optional message this file is attached to. */
  @IsOptional()
  @IsUUID()
  messageId?: string;

  /** Optional override of the stored display name (defaults to original filename). */
  @IsOptional()
  @IsString()
  name?: string;
}

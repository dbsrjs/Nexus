import { IsNotEmpty, IsObject, IsOptional, IsString, IsUUID } from 'class-validator';

/**
 * Input for NotificationsService.create() — used by other services
 * (messages, issues, notices …) to push a notification to a user.
 */
export class CreateNotificationDto {
  /** Recipient user id. */
  @IsUUID()
  userId: string;

  /** Notification type, e.g. 'message:new', 'issue:updated', 'notice:new'. */
  @IsString()
  @IsNotEmpty()
  type: string;

  /** Arbitrary JSON payload (channelId, messageId, preview text, …). */
  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}

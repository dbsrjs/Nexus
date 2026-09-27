import { IsBoolean } from 'class-validator';

/** PUT .../channels/:channelId/mute — 켜고 끄는 값을 그대로 받는다(멱등). */
export class MuteChannelDto {
  @IsBoolean()
  muted!: boolean;
}

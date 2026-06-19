import { SetMetadata } from '@nestjs/common';

export type ChannelActionType = 'view' | 'send';

export const CHANNEL_ACTION_KEY = 'channel_action';

/**
 * Declares whether a channel-scoped route requires can_view or can_send.
 * Read by ChannelPermissionGuard. Defaults to 'view' when absent.
 *
 * Usage:
 *   @ChannelAction('send')
 *   @Post('channels/:id/messages')
 */
export const ChannelAction = (action: ChannelActionType) =>
  SetMetadata(CHANNEL_ACTION_KEY, action);

export const CHANNEL_PARAM_KEY = 'channel_param';

/**
 * Overrides which route param holds the channel id (default: 'channelId',
 * falling back to 'id'). Use on routes like `:id` that represent a channel.
 *
 * Usage:
 *   @ChannelParam('id')
 */
export const ChannelParam = (param: string) =>
  SetMetadata(CHANNEL_PARAM_KEY, param);

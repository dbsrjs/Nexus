import { SetMetadata } from '@nestjs/common';

/** Metadata key marking a route as accessible without authentication. */
export const IS_PUBLIC_KEY = 'isPublic';

/** Marks a route (or controller) as public so the global JwtAuthGuard skips it. */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

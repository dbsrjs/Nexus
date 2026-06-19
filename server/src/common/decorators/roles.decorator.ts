import { SetMetadata } from '@nestjs/common';
import { Role } from '@prisma/client';

export const ROLES_KEY = 'roles';

/**
 * Restricts a route (or controller) to the given global roles.
 * Enforced by RolesGuard.
 *
 * Usage:
 *   @Roles('admin')
 *   @Roles('admin', 'lead')
 */
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);

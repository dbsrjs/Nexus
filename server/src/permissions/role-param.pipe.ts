import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';
import { Role } from '@prisma/client';

/**
 * Validates a `:role` route param against the Role enum so the
 * permission matrix endpoint only accepts admin/lead/member/guest.
 */
@Injectable()
export class RoleParamPipe implements PipeTransform<string, Role> {
  transform(value: string): Role {
    if (!Object.values(Role).includes(value as Role)) {
      throw new BadRequestException(
        `Invalid role '${value}'. Expected one of: ${Object.values(Role).join(', ')}`,
      );
    }
    return value as Role;
  }
}

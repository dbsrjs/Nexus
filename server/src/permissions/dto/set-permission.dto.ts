import { IsBoolean } from 'class-validator';

export class SetPermissionDto {
  @IsBoolean()
  canView: boolean;

  @IsBoolean()
  canSend: boolean;
}

import { IsEmail, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다' })
  email!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(128)
  password!: string;

  /** signup.dto.ts 의 client 와 같은 의미. */
  @IsOptional()
  @IsIn(['web', 'native'])
  client?: 'web' | 'native';
}

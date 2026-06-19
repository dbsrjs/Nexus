import {
  IsDateString,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

/**
 * Body for POST /api/worklogs. `date` defaults to today (server-side) when
 * omitted. The owning user is taken from the JWT, never the body.
 */
export class CreateWorklogDto {
  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  tag?: string;

  @IsString()
  @IsNotEmpty()
  body!: string;
}

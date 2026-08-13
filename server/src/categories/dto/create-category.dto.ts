import { IsInt, IsOptional, IsString, MaxLength, Min, MinLength } from 'class-validator';

export class CreateCategoryDto {
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  name!: string;

  /** 비우면 맨 뒤에 붙는다. */
  @IsOptional()
  @IsInt()
  @Min(0)
  position?: number;
}

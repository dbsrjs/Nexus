import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { SpaceGuard } from '../spaces/guards/space.guard';
import { SpaceRoleGuard } from '../spaces/guards/space-role.guard';
import { MinRole } from '../spaces/decorators/min-role.decorator';

/** GET /api/spaces/:spaceId/categories 외 (docs/백엔드-설계.md §4) */
@Controller('spaces/:spaceId/categories')
@UseGuards(SpaceGuard, SpaceRoleGuard)
export class CategoriesController {
  constructor(private readonly categories: CategoriesService) {}

  @Get()
  list(@Param('spaceId', new ParseUUIDPipe()) spaceId: string) {
    return this.categories.list(spaceId);
  }

  @Post()
  @MinRole('admin')
  create(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Body() dto: CreateCategoryDto,
  ) {
    return this.categories.create(spaceId, dto);
  }

  @Patch(':categoryId')
  @MinRole('admin')
  update(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('categoryId', new ParseUUIDPipe()) categoryId: string,
    @Body() dto: UpdateCategoryDto,
  ) {
    return this.categories.update(spaceId, categoryId, dto);
  }

  @Delete(':categoryId')
  @MinRole('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @Param('spaceId', new ParseUUIDPipe()) spaceId: string,
    @Param('categoryId', new ParseUUIDPipe()) categoryId: string,
  ) {
    return this.categories.remove(spaceId, categoryId);
  }
}

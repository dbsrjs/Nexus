import { Injectable, NotFoundException } from '@nestjs/common';
import { Category } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

/**
 * 채널을 묶는 그룹. 스페이스에 속한다.
 *
 * 모든 메서드가 `spaceId` 를 첫 인자로 받고 WHERE 에 넣는다 —
 * SpaceGuard 를 통과했더라도 다른 스페이스의 카테고리 id 를 넘기면 404 가 되도록
 * (docs/백엔드-설계.md §2 격리 규칙 2).
 */
@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  list(spaceId: string): Promise<Category[]> {
    return this.prisma.category.findMany({
      where: { spaceId },
      orderBy: [{ position: 'asc' }, { createdAt: 'asc' }],
    });
  }

  async create(spaceId: string, dto: CreateCategoryDto): Promise<Category> {
    // position 을 주지 않으면 맨 뒤에 붙인다.
    const position = dto.position ?? (await this.nextPosition(spaceId));

    return this.prisma.category.create({
      data: { spaceId, name: dto.name.trim(), position },
    });
  }

  async update(
    spaceId: string,
    categoryId: string,
    dto: UpdateCategoryDto,
  ): Promise<Category> {
    await this.requireCategory(spaceId, categoryId);

    return this.prisma.category.update({
      where: { id: categoryId },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.position !== undefined ? { position: dto.position } : {}),
      },
    });
  }

  /**
   * 카테고리를 지워도 채널은 남는다 (`categoryId` 가 null 이 되어 미분류로 간다).
   * 스키마의 onDelete: SetNull 이 그것을 보장한다 — 카테고리 삭제로 대화가
   * 사라지는 일은 없어야 한다.
   */
  async remove(spaceId: string, categoryId: string): Promise<void> {
    await this.requireCategory(spaceId, categoryId);
    await this.prisma.category.delete({ where: { id: categoryId } });
  }

  private async nextPosition(spaceId: string): Promise<number> {
    const last = await this.prisma.category.findFirst({
      where: { spaceId },
      orderBy: { position: 'desc' },
      select: { position: true },
    });
    return (last?.position ?? -1) + 1;
  }

  private async requireCategory(
    spaceId: string,
    categoryId: string,
  ): Promise<Category> {
    const category = await this.prisma.category.findFirst({
      where: { id: categoryId, spaceId },
    });
    if (!category) {
      throw new NotFoundException('카테고리를 찾을 수 없습니다');
    }
    return category;
  }
}

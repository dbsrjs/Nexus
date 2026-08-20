import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Sprint, SprintState } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { buildBurndown } from './burndown';
import {
  CreateSprintDto,
  ListSprintsDto,
  UpdateSprintDto,
} from './dto/sprint.dto';

/** 화면에 보이는 순서. enum 선언 순서와 다르다 — 도는 것이 맨 위다. */
const SPRINT_ORDER: Record<SprintState, number> = {
  active: 0,
  planned: 1,
  closed: 2,
};

/**
 * 스프린트. **이슈와 별도 모듈이다** — 자기 수명주기와 번다운을 갖는 독립된
 * 것이라, `issues/` 에 넣으면 그 모듈이 부푼다(설계 §1).
 *
 * `sprintId` 가 비어 있는 이슈의 집합이 곧 백로그다. 백로그 테이블은 없다.
 */
@Injectable()
export class SprintsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(spaceId: string, dto: ListSprintsDto): Promise<Sprint[]> {
    const sprints = await this.prisma.sprint.findMany({
      where: { spaceId, ...(dto.state ? { state: dto.state } : {}) },
      orderBy: { createdAt: 'desc' },
    });

    // **선언 순서에 기대지 않는다.** Prisma 의 enum 정렬은 스키마 선언 순서
    // (planned · active · closed)라, 그대로 쓰면 도는 스프린트가 계획 뒤로
    // 밀린다. 지금 하는 일이 맨 위에 있어야 한다.
    return sprints.sort(
      (a, b) => SPRINT_ORDER[a.state] - SPRINT_ORDER[b.state],
    );
  }

  create(spaceId: string, dto: CreateSprintDto): Promise<Sprint> {
    return this.prisma.sprint.create({
      data: {
        spaceId,
        name: dto.name.trim(),
        goal: dto.goal?.trim() || null,
        startsAt: dto.startsAt ? new Date(dto.startsAt) : null,
        endsAt: dto.endsAt ? new Date(dto.endsAt) : null,
      },
    });
  }

  async update(
    spaceId: string,
    sprintId: string,
    dto: UpdateSprintDto,
  ): Promise<Sprint> {
    const current = await this.requireSprint(spaceId, sprintId);

    if (dto.state !== undefined && dto.state !== current.state) {
      this.assertTransition(current.state, dto.state);
      if (dto.state === SprintState.active) {
        await this.assertNoOtherActive(spaceId, sprintId);
      }
    }

    return this.prisma.sprint.update({
      where: { id: sprintId },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.goal !== undefined ? { goal: dto.goal?.trim() || null } : {}),
        ...(dto.startsAt !== undefined
          ? { startsAt: dto.startsAt ? new Date(dto.startsAt) : null }
          : {}),
        ...(dto.endsAt !== undefined
          ? { endsAt: dto.endsAt ? new Date(dto.endsAt) : null }
          : {}),
        ...(dto.state !== undefined ? { state: dto.state } : {}),
      },
    });
  }

  /**
   * 스프린트를 지운다. 이슈는 `sprintId` 가 `SetNull` 이라 **백로그로 돌아간다** —
   * 스프린트가 사라졌다고 할 일이 사라지면 안 된다(이슈의 부모 삭제와 같은 판단).
   */
  async remove(spaceId: string, sprintId: string): Promise<void> {
    await this.requireSprint(spaceId, sprintId);
    await this.prisma.sprint.delete({ where: { id: sprintId } });
  }

  /**
   * 번다운. `closedAt` 하나로 날짜별 남은 양을 역산한다(설계 §6-2).
   *
   * **닫힌 스프린트도 그릴 수 있다.** 닫을 때 미완료 이슈의 `sprintId` 를
   * 건드리지 않기 때문이다 — 그 기록이 남아 있어야 지난 스프린트를 되돌아본다.
   */
  async burndown(spaceId: string, sprintId: string) {
    const sprint = await this.requireSprint(spaceId, sprintId);

    if (!sprint.startsAt || !sprint.endsAt) {
      // planned 상태로 날짜 없이 만들어 둘 수 있으므로 실제로 일어난다.
      throw new BadRequestException('스프린트에 기간이 없어 번다운을 그릴 수 없습니다');
    }
    if (sprint.endsAt < sprint.startsAt) {
      throw new BadRequestException('스프린트 종료일이 시작일보다 앞섭니다');
    }

    const issues = await this.prisma.issue.findMany({
      where: { spaceId, sprintId },
      select: { storyPoints: true, closedAt: true },
    });

    const { total, days } = buildBurndown({
      startsAt: sprint.startsAt,
      endsAt: sprint.endsAt,
      issues,
    });

    return {
      sprintId: sprint.id,
      startsAt: sprint.startsAt,
      endsAt: sprint.endsAt,
      total,
      days,
    };
  }

  /**
   * `planned → active → closed` 한 방향이다.
   *
   * 닫은 것을 다시 여는 길을 두지 않는 이유는, 되돌릴 일이 생기면 **새
   * 스프린트를 만드는 편이 정직하기** 때문이다 — 되살린 스프린트의 번다운은
   * 두 기간이 섞여 읽을 수 없게 된다.
   */
  private assertTransition(from: SprintState, to: SprintState): void {
    const allowed: Record<SprintState, SprintState[]> = {
      planned: [SprintState.active],
      active: [SprintState.closed],
      closed: [],
    };
    if (!allowed[from].includes(to)) {
      throw new BadRequestException(
        `스프린트를 ${from} 에서 ${to} 로 바꿀 수 없습니다`,
      );
    }
  }

  /** 스페이스당 도는 스프린트는 하나다. 둘이면 "지금 하는 일"이 뜻을 잃는다. */
  private async assertNoOtherActive(
    spaceId: string,
    sprintId: string,
  ): Promise<void> {
    const other = await this.prisma.sprint.findFirst({
      where: { spaceId, state: SprintState.active, id: { not: sprintId } },
      select: { name: true },
    });
    if (other) {
      throw new ConflictException(
        `이미 진행 중인 스프린트가 있습니다: ${other.name}`,
      );
    }
  }

  private async requireSprint(
    spaceId: string,
    sprintId: string,
  ): Promise<Sprint> {
    const sprint = await this.prisma.sprint.findFirst({
      where: { id: sprintId, spaceId },
    });
    // 403 이 아니라 404 다 — 403 은 "그 스프린트가 존재한다"를 알려 준다.
    if (!sprint) throw new NotFoundException('스프린트를 찾을 수 없습니다');
    return sprint;
  }
}

import { PrismaService } from '../prisma/prisma.service';
import { RealtimeEmitter } from '../realtime/realtime-emitter';

export interface UserUpdatedPayload {
  userId: string;
  name: string;
  avatarUrl: string | null;
}

/**
 * 이름이나 사진이 바뀌었음을 알린다 — **둘 다 싣는다.** 받는 쪽이 무엇이
 * 바뀌었는지 가리지 않고 덮어쓰면 된다 (14단계 설계 §1).
 *
 * 그 사용자가 속한 **스페이스 룸마다** 보낸다. 이름 · 사진은 받는 사람마다 같은
 * 값이라 브로드캐스트해도 된다(CLAUDE.md §3-6). 스페이스를 함께 쓰지 않는 사람은
 * 그 룸에 없으므로 받지 않는다. 스페이스가 하나도 없어도 내 다른 기기는 알아야
 * 하므로 **사용자 룸에도** 보낸다 — 두 번 받는 기기는 같은 값으로 두 번 덮을 뿐이다.
 */
export async function broadcastUserUpdated(
  prisma: PrismaService,
  realtime: RealtimeEmitter,
  user: { id: string; name: string; avatarUrl: string | null },
): Promise<void> {
  const payload: UserUpdatedPayload = {
    userId: user.id,
    name: user.name,
    avatarUrl: user.avatarUrl,
  };
  const spaces = await prisma.spaceMember.findMany({
    where: { userId: user.id },
    select: { spaceId: true },
  });
  for (const { spaceId } of spaces) {
    realtime.toSpace(spaceId, 'user:updated', payload);
  }
  realtime.toUser(user.id, 'user:updated', payload);
}

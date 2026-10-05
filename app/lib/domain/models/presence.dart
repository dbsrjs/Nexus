/// 사람의 상태(17단계 설계 D14). 오프라인은 서버 지도에 없다는 뜻이다.
enum Presence { online, away, offline }

Presence presenceFromWire(Object? wire) => switch (wire) {
      'online' => Presence.online,
      'away' => Presence.away,
      _ => Presence.offline,
    };

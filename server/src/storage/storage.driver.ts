import { Readable } from 'stream';

/**
 * 바이트를 어디에 두는지만 아는 계층.
 *
 * **URL 을 만드는 메서드가 없는 것이 이 인터페이스의 핵심이다.** 서명 URL 을
 * 발급하면 그 주소는 `SpaceGuard` 를 지나지 않는다 — 한 번 나가면 만료 전까지
 * 스페이스 밖에서도 열린다. 테넌트 격리가 최우선이라는 규칙(설계 §2)과 정면으로
 * 어긋나므로, 첨부는 **언제나 서버를 통해 스트리밍한다.**
 *
 * 덕분에 구현을 바꿔도 클라이언트가 보는 주소가 변하지 않는다. 개발은 로컬
 * 디스크, 배포는 S3 호환 스토리지를 쓰되 앱은 그 차이를 모른다.
 */
export abstract class StorageDriver {
  /** 사람이 읽을 이름. 부팅 로그와 검증 스크립트가 어느 구현인지 알리는 용도다. */
  abstract readonly name: string;

  abstract put(key: string, body: Readable | Buffer, mime?: string): Promise<void>;

  abstract get(key: string): Promise<Readable>;

  abstract delete(key: string): Promise<void>;

  abstract exists(key: string): Promise<boolean>;
}

/**
 * 오브젝트 키를 만든다. `2026/08/uuid.png` 꼴이다.
 *
 * 날짜로 나누는 이유는 로컬 디스크 때문이다 — 한 디렉터리에 파일이 수만 개
 * 쌓이면 파일시스템이 느려진다. S3 에서는 그냥 키의 일부일 뿐이라 손해가 없다.
 *
 * **원본 파일명을 키에 쓰지 않는다.** 사용자가 준 문자열이라 경로 탈출(`../`)과
 * 한글·공백 인코딩 문제가 따라온다. 보이는 이름은 DB 의 `name` 이 들고 있다.
 */
export function buildStorageKey(id: string, ext?: string | null): string {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, '0');
  return `${year}/${month}/${id}${ext ? `.${ext}` : ''}`;
}

/**
 * `BigInt` 를 JSON 으로 직렬화할 수 있게 한다.
 *
 * Prisma 는 Postgres 의 `bigint` 컬럼을 JS `BigInt` 로 돌려주는데,
 * `JSON.stringify` 는 BigInt 를 만나면 **TypeError 를 던진다.** Nest 가 응답을
 * 만들 때 이 함수를 쓰므로, bigint 컬럼이 한 개라도 섞인 객체를 그대로
 * 반환하면 그 엔드포인트는 **항상 500** 이 된다.
 *
 * 실제로 `GET /api/spaces` 가 이 이유로 500 이었다 — `spaces.storage_used_bytes`
 * 때문이다. 스페이스 목록은 로그인 직후 첫 화면이라, 앱이 아예 진입하지 못한다.
 *
 * 문자열로 내보낸다. 숫자로 바꾸면 2^53 을 넘는 값이 조용히 뭉개지는데,
 * 바이트 수를 다루는 컬럼(`storage_used_bytes`, `attachments.size_bytes`)에서
 * 그런 손실은 눈에 띄지 않게 틀린 값을 만든다. 문자열이면 클라이언트가
 * 어떻게 다룰지 스스로 정한다.
 *
 * Decimal(`issues.position`)과 Date 는 이미 toJSON 을 갖고 있어 손댈 필요가 없다.
 */
export function enableBigIntSerialization(): void {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (BigInt.prototype as any).toJSON = function (this: bigint): string {
    return this.toString();
  };
}
